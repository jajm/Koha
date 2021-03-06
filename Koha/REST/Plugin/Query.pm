package Koha::REST::Plugin::Query;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Mojo::Base 'Mojolicious::Plugin';
use List::MoreUtils qw(any);
use Scalar::Util qw(reftype);

use Koha::Exceptions;

=head1 NAME

Koha::REST::Plugin::Query

=head1 API

=head2 Mojolicious::Plugin methods

=head3 register

=cut

sub register {
    my ( $self, $app ) = @_;

=head2 Helper methods

=head3 extract_reserved_params

    my ( $filtered_params, $reserved_params ) = $c->extract_reserved_params($params);

Generates the DBIC query from the query parameters.

=cut

    $app->helper(
        'extract_reserved_params' => sub {
            my ( $c, $params ) = @_;

            my $reserved_params;
            my $filtered_params;
            my $path_params;

            my $reserved_words = _reserved_words();
            my @query_param_names = keys %{$c->req->params->to_hash};

            foreach my $param ( keys %{$params} ) {
                if ( grep { $param eq $_ } @{$reserved_words} ) {
                    $reserved_params->{$param} = $params->{$param};
                }
                elsif ( grep { $param eq $_ } @query_param_names ) {
                    $filtered_params->{$param} = $params->{$param};
                }
                else {
                    $path_params->{$param} = $params->{$param};
                }
            }

            return ( $filtered_params, $reserved_params, $path_params );
        }
    );

=head3 dbic_merge_sorting

    $attributes = $c->dbic_merge_sorting({ attributes => $attributes, params => $params });

Generates the DBIC order_by attributes based on I<$params>, and merges into I<$attributes>.

=cut

    $app->helper(
        'dbic_merge_sorting' => sub {
            my ( $c, $args ) = @_;
            my $attributes = $args->{attributes};
            my $result_set = $args->{result_set};

            if ( defined $args->{params}->{_order_by} ) {
                my $order_by = $args->{params}->{_order_by};
                if ( reftype($order_by) and reftype($order_by) eq 'ARRAY' ) {
                    my @order_by = map { _build_order_atom({ string => $_, result_set => $result_set }) }
                                @{ $args->{params}->{_order_by} };
                    $attributes->{order_by} = \@order_by;
                }
                else {
                    $attributes->{order_by} = _build_order_atom({ string => $order_by, result_set => $result_set });
                }
            }

            return $attributes;
        }
    );

=head3 _build_query_params_from_api

    my $params = _build_query_params_from_api( $filtered_params, $reserved_params );

Builds the params for searching on DBIC based on the selected matching algorithm.
Valid options are I<contains>, I<starts_with>, I<ends_with> and I<exact>. Default is
I<contains>. If other value is passed, a Koha::Exceptions::WrongParameter exception
is raised.

=cut

    $app->helper(
        'build_query_params' => sub {

            my ( $c, $filtered_params, $reserved_params ) = @_;

            my $params;
            my $match = $reserved_params->{_match} // 'contains';

            foreach my $param ( keys %{$filtered_params} ) {
                if ( $match eq 'contains' ) {
                    $params->{$param} =
                      { like => '%' . $filtered_params->{$param} . '%' };
                }
                elsif ( $match eq 'starts_with' ) {
                    $params->{$param} = { like => $filtered_params->{$param} . '%' };
                }
                elsif ( $match eq 'ends_with' ) {
                    $params->{$param} = { like => '%' . $filtered_params->{$param} };
                }
                elsif ( $match eq 'exact' ) {
                    $params->{$param} = $filtered_params->{$param};
                }
                else {
                    # We should never reach here, because the OpenAPI plugin should
                    # prevent invalid params to be passed
                    Koha::Exceptions::WrongParameter->throw(
                        "Invalid value for _match param ($match)");
                }
            }

            return $params;
        }
    );

=head3 stash_embed

    $c->stash_embed( $c->match->endpoint->pattern->defaults->{'openapi.op_spec'} );

=cut

    $app->helper(
        'stash_embed' => sub {

            my ( $c, $args ) = @_;

            my $spec = $args->{spec} // {};

            my $embed_spec   = $spec->{'x-koha-embed'};
            my $embed_header = $c->req->headers->header('x-koha-embed');

            Koha::Exceptions::BadParameter->throw("Embedding objects is not allowed on this endpoint.")
                if $embed_header and !defined $embed_spec;

            if ( $embed_header ) {
                my $THE_embed = {};
                foreach my $embed_req ( split /\s*,\s*/, $embed_header ) {
                    my $matches = grep {lc $_ eq lc $embed_req} @{ $embed_spec };

                    Koha::Exceptions::BadParameter->throw(
                        error => 'Embeding '.$embed_req. ' is not authorised. Check your x-koha-embed headers or remove it.'
                    ) unless $matches;

                    _merge_embed( _parse_embed($embed_req), $THE_embed);
                }

                $c->stash( 'koha.embed' => $THE_embed )
                    if $THE_embed;
            }

            return $c;
        }
    );
}

=head2 Internal methods

=head3 _reserved_words

    my $reserved_words = _reserved_words();

=cut

sub _reserved_words {

    my @reserved_words = qw( _match _order_by _page _per_page );
    return \@reserved_words;
}

=head3 _build_order_atom

    my $order_atom = _build_order_atom( $string );

Parses I<$string> and outputs data valid for using in SQL::Abstract order_by attribute
according to the following rules:

     string -> I<string>
    +string -> I<{ -asc => string }>
    -string -> I<{ -desc => string }>

=cut

sub _build_order_atom {
    my ( $args )   = @_;
    my $string     = $args->{string};
    my $result_set = $args->{result_set};

    my $param = $string;
    $param =~ s/^(\+|\-|\s)//;
    if ( $result_set ) {
        my $model_param = $result_set->from_api_mapping->{$param};
        $param = $model_param if defined $model_param;
    }

    if ( $string =~ m/^\+/ or
         $string =~ m/^\s/ ) {
        # asc order operator present
        return { -asc => $param };
    }
    elsif ( $string =~ m/^\-/ ) {
        # desc order operator present
        return { -desc => $param };
    }
    else {
        # no order operator present
        return $param;
    }
}

=head3 _parse_embed

    my $embed = _parse_embed( $string );

Parses I<$string> and outputs data valid for passing to the Kohaa::Object(s)->to_api
method.

=cut

sub _parse_embed {
    my $string = shift;

    my $result;
    my ( $curr, $next ) = split /\s*\.\s*/, $string, 2;

    if ( $next ) {
        $result->{$curr} = { children => _parse_embed( $next ) };
    }
    else {
        if ( $curr =~ m/^(?<relation>.*)\+count/ ) {
            my $key = $+{relation} . "_count";
            $result->{$key} = { is_count => 1 };
        }
        else {
            $result->{$curr} = {};
        }
    }

    return $result;
}

=head3 _merge_embed

    _merge_embed( $parsed_embed, $global_embed );

Merges the hash referenced by I<$parsed_embed> into I<$global_embed>.

=cut

sub _merge_embed {
    my ( $structure, $embed ) = @_;

    my ($root) = keys %{ $structure };

    if ( any { $root eq $_ } keys %{ $embed } ) {
        # Recurse
        _merge_embed( $structure->{$root}, $embed->{$root} );
    }
    else {
        # Embed
        $embed->{$root} = $structure->{$root};
    }
}

1;
