use utf8;
package Koha::Schema::Result::City;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::City

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cities>

=cut

__PACKAGE__->table("cities");

=head1 ACCESSORS

=head2 cityid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 city_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

=head2 city_state

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 city_country

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 city_zipcode

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "cityid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "city_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 100 },
  "city_state",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "city_country",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "city_zipcode",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cityid>

=back

=cut

__PACKAGE__->set_primary_key("cityid");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-10-14 20:56:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zEjfS65sp13yF7dH8/ojZQ

sub koha_objects_class {
    'Koha::Cities';
}

1;
