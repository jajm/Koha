use strict;
use warnings;

use C4::Installer;
use C4::Languages;

my $installer = C4::Installer->new();

$installer->load_db_schema();
$installer->set_marcflavour_syspref('MARC21');
my (undef, $fwklist) = $installer->marc_framework_sql_list('en', 'MARC21');
my (undef, $list) = $installer->sample_data_sql_list('en');
my @frameworks;
foreach my $fwk (@$fwklist, @$list) {
    foreach my $framework (@{ $fwk->{frameworks} }) {
        push @frameworks, $framework->{fwkfile};
    }
}
my $all_languages = C4::Languages::getAllLanguages();
$installer->load_sql_in_order($all_languages, @frameworks);
$installer->set_version_syspref();

require Koha::SearchEngine::Elasticsearch;
Koha::SearchEngine::Elasticsearch->reset_elasticsearch_mappings;

require Koha::CirculationRules;
Koha::CirculationRules->set_rules({
    branchcode      => undef,
    categorycode => undef,
    itemtype        => undef,
    rules => {
        renewalsallowed => 5,
        renewalperiod => 5,
        issuelength => 5,
        lengthunit => 'days',
        onshelfholds => 1,
        article_requests => 'yes',
        auto_renew => 0,
        cap_fine_to_replacement_price => 0,
        chargeperiod => undef,
        chargeperiod_charge_at => 0,
        fine => 0,
        finedays => 0,
        firstremind => 0,
        hardduedate => '',
        hardduedatecompare => -1,
        holds_per_day => '',
        holds_per_record => 2,
        maxissueqty => 5,
        maxonsiteissueqty => 5,
        maxsuspensiondays => '',
        no_auto_renewal_after => '',
        no_auto_renewal_after_hard_limit => '',
        norenewalbefore => '',
        opacitemholds => 'Y',
        overduefinescap => '',
        rentaldiscount => 0,
        suspension_chargeperiod => undef,
        reservesallowed => '',
    }
});

# Some tests use the borrowernumber 51, so we have to create it
# First 50 borrowers are created by C4::Installer
require Koha::Patron;
Koha::Patron->new({
    categorycode => 'S',
    branchcode => 'CPL',
    cardnumber => '001',
    userid => '001',
})->store();
