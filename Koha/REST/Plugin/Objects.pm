package Koha::REST::Plugin::Objects;

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

=head1 NAME

Koha::REST::Plugin::Objects

=head1 API

=head2 Helper methods

=head3 objects.search

    my $patrons_rs = Koha::Patrons->new;
    my $patrons = $c->objects->search( $patrons_rs );

Performs a database search using given Koha::Objects object and query parameters.

Returns an arrayref of the hashrefs representing the resulting objects
for API rendering.

=cut

sub register {
    my ( $self, $app ) = @_;

    $app->helper(
        'objects.search' => sub {
            my ( $c, $result_set ) = @_;

            my $args = $c->validation->output;
            my $attributes = {};

            # Extract reserved params
            my ( $filtered_params, $reserved_params, $path_params ) = $c->extract_reserved_params($args);
            # Look for embeds
            my $embed = $c->stash('koha.embed');

            # Merge sorting into query attributes
            $c->dbic_merge_sorting(
                {
                    attributes => $attributes,
                    params     => $reserved_params,
                    result_set => $result_set
                }
            );

            # Merge pagination into query attributes
            $c->dbic_merge_pagination(
                {
                    filter => $attributes,
                    params => $reserved_params
                }
            );

            # Call the to_model function by reference, if defined
            if ( defined $filtered_params ) {

                # Apply the mapping function to the passed params
                $filtered_params = $result_set->attributes_from_api($filtered_params);
                $filtered_params = $c->build_query_params( $filtered_params, $reserved_params );
            }

            if ( defined $path_params ) {

                # Apply the mapping function to the passed params
                $filtered_params //= {};
                $path_params = $result_set->attributes_from_api($path_params);
                foreach my $param (keys %{$path_params}) {
                    $filtered_params->{$param} = $path_params->{$param};
                }
            }

            # Perform search
            my $objects = $result_set->search( $filtered_params, $attributes );

            if ($objects->is_paged) {
                $c->add_pagination_headers({
                    total => $objects->pager->total_entries,
                    params => $args,
                });
            }

            return $objects->to_api({ embed => $embed });
        }
    );
}

1;
