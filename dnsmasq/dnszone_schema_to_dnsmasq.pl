#!/usr/bin/env perl
use strict;
use warnings;
use Net::LDAP::LDIF;
use v5.14;
use Data::Dumper;

my $file =  shift || "/root/dns.ldif";

my $hosts = "/etc/hosts";
my $dnsmasq = "/etc/dnsmasq.conf";

my $ldif = Net::LDAP::LDIF->new( $file, "r",  onerror => 'die' );

while ( not $ldif->eof() ) {
    open DNS, ">>", $dnsmasq || die "Error $!";
    open HOST, ">>", $hosts || die "Error $!";

    my $entrys =  $ldif->read_entry();

    foreach my $entry ( $entrys ) {
        if ( $entry->dn =~ /privateZones/ ) {
            given ( $entry ) {
                when ( $entry->get_value("arecord") ) {
                        if ( $entry->get_value("relativedomainname") eq "@" )  {
                            &server($entry);
                        }else{
                            &arecord($entry);
                        }
                }
                when ( $entry->get_value("mxrecord") ) { &mxrecord($entry) }
                when ( $entry->get_value("cnamerecord") ) {
                    if ( $entry->get_value("relativedomainname") ne "@" ) {
                        &cnamerecord($entry);
                    }
                }
                when ( $entry->get_value("txtrecord") ) { &txtrecord($entry) }
                when ( $entry->get_value("ptrrecord") ) { &ptrrecord($entry) }
            }
        }
    }

    close HOST;
    close DNS;
}

sub arecord {
    my $entry = shift;

    foreach my $a ( $entry->get_value("relativedomainname") ) {
        my $arecord = $entry->get_value("arecord").
            " ".
            $a.
            ".".
            $entry->get_value("zonename").
            " ".
            $a;

        print HOST $arecord."\n";
    }

}

sub mxrecord {
    my $entry = shift;

    foreach my $mx ( $entry->get_value("mxrecord") ) {
        my ($preference, $host) = split(" ", $mx);

        $host =~ s/\.$//g;

        my $mxrecord = "mx-host=".
            $host.".".$entry->get_value("zonename").
            ",".
            $entry->get_value("zonename").
            ",".
            $preference;
        print DNS $mxrecord."\n";
    }
}

sub cnamerecord {
    my $entry = shift;

    foreach my $cname ( $entry->get_value("cnamerecord") ) {
        my $cnamerecord = "cname=".
                $entry->get_value("relativedomainname").
                ",".
                $cname;

        print DNS $cnamerecord."\n";
    }
}

sub txtrecord {
    my $entry = shift;

    foreach my $txt ( $entry->get_value("txtrecord") ) {
        my $zone;

        if ( $entry->get_value("relativedomainname") eq "@" ) {
            $zone = $entry->get_value("zonename");
        }else{
            $zone = $entry->get_value("relativedomainname").".".$entry->get_value("zonename");
        }

        my $txtrecord = "txt-record=".
            $zone.
            ",".
            $txt;

        print DNS $txtrecord."\n";
    }
}

sub ptrrecord {
    my $entry = shift;

    foreach my $ptr ($entry->get_value("ptrrecord")) {
        $ptr =~ s/\.$//g;

        my $zone = $entry->get_value("zonename");
        $zone =~ s/$/\./g;

        my $ptrrecord = "ptr-record=".
            $zone.
            ",".
            "\"".
            $ptr.
            "\"";

        print DNS $ptrrecord."\n";
    }
}

sub dnsttl {
    my $entry = shift;

    my $dnsttl = "neg-ttl=".$entry->get_value("dnsttl");

    return $dnsttl;
}

sub server {
    my $entry = shift;

    my $server = "server=".
        "/".
        $entry->get_value("zonename").
        "/".
        $entry->get_value("arecord");

    print DNS $server."\n";
}
