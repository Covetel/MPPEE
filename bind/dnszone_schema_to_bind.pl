#!/usr/bin/env perl
use strict;
use warnings;
use Net::LDAP::LDIF;
use v5.14;
use Data::Dumper;

my $ld =  shift || "/home/aphu/Documents/Covetel/MPPEE/MPPEE-Covetel/dns.ldif";

#my $prefix = "/etc/bind";
my $prefix = "/home/aphu/Documents/Covetel/MPPEE/bind/examples";
my $named = $prefix."/named.conf.zones";

my @zones;
my @named_zones;

my $ldif = Net::LDAP::LDIF->new( $ld, "r",  onerror => 'die' );

while ( not $ldif->eof() ) {

    my $entrys =  $ldif->read_entry();

    foreach my $entry ( $entrys ) {
        &build_zones($entry);
    }

}

open NAMED, ">>", $named || die "Error $!";
print NAMED @named_zones;
close NAMED;

sub build_zones {
    my ($entry) = shift;
    if ( $entry->dn =~ /publicZones/ ) {
        unless ($entry->get_value('zonename') ~~ @zones) {
            my $zone;
            if ($entry->get_value('zonename') =~ m/^(.*)\.(.*)\.(in-addr.arpa)/) {
                $zone = 'zone "'.$2.".".$3.'" {'."\n\ttype master;\n\tfile \"".&gen_file($entry->get_value('zonename'))."\";\n};\n\n";
                &populate_zone($entry);
            }else{
                $zone = 'zone "'.$entry->get_value('zonename').'" {'."\n\ttype master;\n\tfile \"".&gen_file($entry->get_value('zonename'))."\";\n};\n\n";
                &populate_zone($entry);
            }
            push (@named_zones, $zone);
            push (@zones, $entry->get_value('zonename'));
        }else{
            &populate_zone($entry);
        }
    }
}

sub gen_file {
    my $f = shift;
    my $file;

    if ($f =~ m/^(.*)\.(.*)\.(in-addr.arpa)/) {
        $file = $prefix."/db.".$2;
    }else{
        $file = $prefix."/".$f.".zone";
    }

    return $file;
}

sub populate_zone {
    my $entry = shift;
    my $record;

    if ($entry->get_value('zonename') =~ /arpa/) {
        open ARPA, ">>", &gen_file($entry->get_value('zonename')) || die "Error $!";
        if ( $entry->get_value('soarecord') ) {
            my @soa = split(" ",  $entry->get_value('soarecord'));
            my ($ns1, $ns2) = map { $_ } $entry->get_value('nsrecord'); 
            my @records = "\$TTL\t".$entry->get_value('dnsttl')."\n".
                $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  SOA  ".$soa[0]." ".$soa[1]." (\n".
                "\t".$soa[2]." ; Serial\n".
                "\t".$soa[3]." ; Refresh\n".
                "\t".$soa[4]." ; Retry\n".
                "\t".$soa[5]." ; Expire\n".
                "\t".$soa[6]." ) ; Negative Cache TTL\n".
                "; \n\n".
                $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  NS  ".$ns1."\n".
                $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  NS  ".$ns2."\n".
                $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  PTR  ".$soa[0]."\n".
                $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  MX  ".$entry->get_value('mxrecord')."\n";
                print ARPA @records;
        }else{
            my @records;
            $entry->get_value('zonename') =~ m/^(.*)\.(.*)\.(.*)\.(in-addr.arpa)/;
            if ( $entry->get_value('ptrrecord') ) {
                my @ptrs = map { $_ } $entry->get_value('ptrrecord'); 
                foreach my $ptr (@ptrs) {
                    push(@records, $2.".".$1.".".$entry->get_value('relativeDomainName')."    ".$entry->get_value('dnsclass')."  PTR  ".$ptr."\n");
                }
            }
            print ARPA @records;
        }
        close ARPA;
    }else{
        open ZONE, ">>", &gen_file($entry->get_value('zonename')) || die "Error $!";
        if ( $entry->get_value('soarecord') ) {
            my @soa = split(" ",  $entry->get_value('soarecord'));
            my ($ns1, $ns2) = map { $_ } $entry->get_value('nsrecord'); 
            my @records = "\$ORIGIN .\n".
                "\$TTL\t".$entry->get_value('dnsttl')."\n".
                $entry->get_value('zonename')."   ".$entry->get_value('dnsclass')."  SOA  ".$soa[0]." ".$soa[1]." (\n".
                "\t".$soa[2]." ; Serial\n".
                "\t".$soa[3]." ; Refresh\n".
                "\t".$soa[4]." ; Retry\n".
                "\t".$soa[5]." ; Expire\n".
                "\t".$soa[6]." ) ; Negative Cache TTL\n".
                "; \n";

                if ($entry->get_value('txtrecord')) {
                    push (@records, "\t"." TXT ".$entry->get_value('txtrecord')."\n\n");
                }
                
                push (@records, "\$ORIGIN ".$entry->get_value('zonename')."\n\n");

                if ($entry->get_value('arecord')) {
                    push (@records, $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  A  ".$entry->get_value('arecord')."\n");
                }
                
                push (@records, $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  NS  ".$ns1."\n".
                $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  NS  ".$ns2."\n".
                $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  PTR  ".$soa[0]."\n".
                $entry->get_value('relativeDomainName')."   ".$entry->get_value('dnsclass')."  MX  ".$entry->get_value('mxrecord')."\n");
                print ZONE @records;
        }else{
            my @records;
            if ( $entry->get_value('cnamerecord') ) {
                my @cnames = map { $_ } $entry->get_value('cnamerecord'); 
                foreach my $cname (@cnames) {
                    push(@records, $cname."    IN  CNAME  ".$entry->get_value('relativedomainname')."\n");
                }
            }
            if ( $entry->get_value('arecord') ) {
                push(@records, $entry->get_value('relativeDomainName')."    IN  A  ".$entry->get_value('arecord')."\n");
            }
            if ( $entry->get_value('mxrecord') ) {
                my @mxs = map { $_ } $entry->get_value('mxrecord'); 
                foreach my $mx (@mxs) {
                    push(@records, $entry->get_value('relativeDomainName')."    IN  MX  ".$mx."\n");
                }
            }
            print ZONE @records;
        }
        close ZONE;
    }
}
