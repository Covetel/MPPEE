#!/usr/bin/env perl
use strict;
use warnings;
use Net::LDAP::LDIF;
use v5.14;
use Data::Dumper;

my $file =  shift || "/root/dns.ldif";

my $hosts = "/etc/hosts";
my $dnsmasq = "/etc/dnsmasq.conf";
my $cnames = "/etc/dnsmasq.d/cname.conf";
my $ptrs = "/etc/dnsmasq.d/ptr.conf";
my $txt = "/etc/dnsmasq.d/txt.conf";
my $mx = "/etc/dnsmasq.d/mx.conf";
my $srvs = "/etc/dnsmasq.d/srv.conf";

my $ldif = Net::LDAP::LDIF->new( $file, "r",  onerror => 'die' );

while ( not $ldif->eof() ) {
    open DNS, ">>", $dnsmasq || die "Error $!";
    open CNAMES, ">>", $cnames || die "Error $!";
    open PTRS, ">>", $ptrs || die "Error $!";
    open TXT, ">>", $txt || die "Error $!";
    open MX, ">>", $mx || die "Error $!";
    open SRVS, ">>", $srvs || die "Error $!";
    open HOST, ">>", $hosts || die "Error $!";

    my $entrys =  $ldif->read_entry();

    foreach my $entry ( $entrys ) {
        if ( $entry->dn =~ /privateZones/ ) {
            if ( $entry->get_value("arecord") ) {
                    if ( $entry->get_value("relativedomainname") eq "@" )  {
                        &server($entry);
                    }else{
                        &arecord($entry);
                    }
            }
            if ( $entry->get_value("mxrecord") ) { &mxrecord($entry) }
            if ( $entry->get_value("cnamerecord") ) {
                if ( $entry->get_value("relativedomainname") ne "@" ) {
                    &cnamerecord($entry);
                }
            }
            if ( $entry->get_value("txtrecord") ) { &txtrecord($entry) }
            if ( $entry->get_value("ptrrecord") ) {
                if ( $entry->get_value("relativedomainname") ne "@" ) {
                    &ptrrecord($entry);
                }
            }
            if ( $entry->get_value("srvrecord") ) { &srvrecord($entry) }
        }
    }

    close HOST;
    close CNAMES;
    close PTRS;
    close SRVS;
    close TXT;
    close MX;
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
        print MX $mxrecord."\n";
    }
}

sub cnamerecord {
    my $entry = shift;

    foreach my $cname ( $entry->get_value("cnamerecord") ) {
        my $cnamerecord = "cname=".
                $entry->get_value("relativedomainname").".".$entry->get_value("zonename").
                ",".
                $cname.".".$entry->get_value("zonename");

        print CNAMES $cnamerecord."\n";
    }
}

sub txtrecord {
    my $entry = shift;

    foreach my $txt ( $entry->get_value("txtrecord") ) {
        my $zone;

        $txt =~ s/[\",\']//g;

        if ( $entry->get_value("relativedomainname") eq "@" ) {
            $zone = $entry->get_value("zonename");
        }else{
            $zone = $entry->get_value("relativedomainname").".".$entry->get_value("zonename");
        }

        my $txtrecord = "txt-record=".
            $zone.
            ",".
            $txt;

        print TXT $txtrecord."\n";
    }
}

sub ptrrecord {
    my $entry = shift;

    foreach my $ptr ($entry->get_value("ptrrecord")) {
        $ptr =~ s/\.$//g;

        my $ptrrecord = "ptr-record=".
            $entry->get_value("relativedomainname").
            ".".
            $entry->get_value("zonename").
            ",".
            $ptr;

        print PTRS $ptrrecord."\n";
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

sub srvrecord {
    my $entry = shift;

    my ($tls, $prio, $port, $ldap) = split(" ", $entry->get_value("srvrecord"));

    foreach my $srv ( $entry->get_value("relativedomainname") ) {
        my $srvrecord = "srv-host=".
                $srv.
                ".".
                $entry->get_value("zonename").
                ",".
                $ldap.
                ".".
                $entry->get_value("zonename").
                ",".
                $port.
                ",".
                $prio;

        print SRVS $srvrecord."\n";
    }
}
