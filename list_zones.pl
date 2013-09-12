#!/usr/bin/env perl
use strict;
use warnings;
use Net::LDAP::LDIF;
use v5.14;
use Data::Dumper;

my $file = "/home/aphu/Documents/Covetel/MPPEE/MPPEE-Covetel/dns.ldif";
my $zone_type = shift || die "Debe indicar el tipo de zona a listar";
my @zones;

my $ldif = Net::LDAP::LDIF->new( $file, "r",  onerror => 'die' );

while ( not $ldif->eof() ) {
    my $entrys =  $ldif->read_entry();

    foreach my $entry ( $entrys ) {
        if ( ($entry->dn =~ /privateZones/) && ( $zone_type eq "private" ) ) {
            unless ($entry->get_value('zoneName') ~~ @zones) {
                push (@zones, $entry->get_value('zoneName'));
            }
        }
        if ( ( $entry->dn =~ /publicZones/ ) && ( $zone_type eq "public" ) ) {
            unless ($entry->get_value('zoneName') ~~ @zones) {
                push (@zones, $entry->get_value('zoneName'));
            }
        }
    }
}

print Dumper(@zones);
