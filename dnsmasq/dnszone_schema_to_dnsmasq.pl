#!/usr/bin/env perl
use strict;
use warnings;
use Net::LDAP::LDIF;
use Data::Dumper;

my $file =  shift || "/home/aphu/Documents/Covetel/MPPEE/MPPEE-Covetel/dns.ldif";

my $hosts = "/etc/hosts";
my $dnsmasq = "/etc/dnsmasq.conf";

my $ldif = Net::LDAP::LDIF->new( $file, "r",  onerror => 'die' );

while ( not $ldif->eof() ) {
    open HOST, ">>", $hosts || die "Error $!"; 
    open DNS, ">>", $dnsmasq || die "Error $!"; 

    my @h;

    my $entrys =  $ldif->read_entry();

    foreach my $entry ( $entrys ) {
            if ( $entry->get_value("arecord") ) { 
                print HOST &pointer($entry)."\n"; 
            }
            if ( $entry->get_value("dnsttl") ) { 
                print DNS &dnsttl($entry)."\n"; 
            }
            if ( $entry->get_value("mxrecord") ) { 
                print DNS &mxrecord($entry)."\n"; 
            }
            if ( $entry->get_value("cnamerecord") ) { 
                print DNS &cnamerecord($entry)."\n"; 
            }
            if ( $entry->get_value("txtrecord") ) { 
                print DNS &txtrecord($entry)."\n"; 
            }
            if ( $entry->get_value("ptrrecord") ) { 
                print DNS &ptrrecord($entry)."\n"; 
            }
    }

    close HOST;
    close DNS;
}

sub pointer {
    my $entry = shift;

    my $pointer = $entry->get_value("arecord").
        " ".
        $entry->get_value("relativedomainname").
        ".".
        $entry->get_value("zonename").
        " ".
        $entry->get_value("relativedomainname");

    return $pointer;
}

sub mxrecord {
    my $entry = shift;

    my ($preference, $host) = split(" ", $entry->get_value("mxrecord"));

    $host =~ s/\.$//g;

    my $mxrecord = "mx-host=".
        $host.
        ",".
        $entry->get_value("zonename").
        ",".
        $preference;

    return $mxrecord;
}

sub cnamerecord {
    my $entry = shift;

    my $cnamerecord = "cname=".
        $entry->get_value("cnamerecord").
        ",".
        $entry->get_value("relativedomainname");

    return $cnamerecord;
}

sub txtrecord {
    my $entry = shift;

    my $txtrecord = "txt-record=".
        $entry->get_value("zonename").
        ",".
        $entry->get_value("txtrecord");

    return $txtrecord;
}

sub ptrrecord {
    my $entry = shift;

    my $ptr = $entry->get_value("ptrrecord");
    $ptr =~ s/\.$//g;

    my $zone = $entry->get_value("zonename");
    $zone =~ s/$/\./g;

    my $ptrrecord = "ptr-record=".
        $zone.
        ",".
        "\"".
        $ptr.
        "\"";

    return $ptrrecord;
}

sub dnsttl {
    my $entry = shift;

    my $dnsttl = "neg-ttl=".$entry->get_value("dnsttl");

    return $dnsttl;
}
