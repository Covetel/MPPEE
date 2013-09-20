#!/usr/bin/env perl
use Net::LDAP::LDIF;
use Test::Simple tests => 150;
use Net::DNS;
use Data::Dumper;
use v5.14;

#Servidores DNS a consultar
my $dns_server = shift || "Debe Suministrar el servidor DNS que se probará.\n";
my @dns_servers;
push (@dns_servers, $dns_server);
#Tipo de Zona a probar
my $target = shift || die "Debe Suministrar el tipo de zona a probar (public/private) como primer argumento.\n";
#LDIF donde estan las zonas
my $ldif =  shift || "/root/dns.ldif";
#Hash de zonas
my $pointers; 
#Atributos a excluir en las entradas
my @exclude_attrs = qw(top dnsttl dnsclass objectclass zonename relativedomainname);
#Mapeo de atributos LDAP
my %map_attr = (
    'nsrecord' => "NS",
    'mxrecord' => "MX",
    'arecord' => "A",
    'cnamerecord' => "CNAME",
    'txtrecord' => "TXT",
    'ptrrecord' => "PTR",
    'soarecord' => "SOA",
);

#Lista con las entradas en el LDIF
my @entrys = &read_ldif($ldif);

#Llamada al método segun el tipo de Zona a probar
$pointers = &get_privates_zones($pointers, \@entrys) if $target eq "private";
$pointers = &get_public_zones($pointers, \@entrys) if $target eq "public";

#Crea lista con los hosts
my @hosts = (keys $pointers);

#Pruebas
my $res = Net::DNS::Resolver->new( nameservers => [@dns_servers] );
#Recorro todos los hosts
foreach my $host (@hosts) {
    foreach my $p (@{$pointers->{$host}->{"type_pointer"}}){
        given ($p) {
            when ("CNAME") {
                foreach my $cnames (@{$pointers->{$host}->{$p}}) {
                    print "Probando ".$cnames." Tipo ".$p."\n";
                    my $query = $res->query($cnames, $p);
                    if ($query) {
                        foreach my $cname ($query->answer) {
                            ok($cnames ~~ @{$pointers->{$host}->{$p}}, "Host: ".$cnames." - Tipo de Puntero: ".$p." - Respuesta ".$cname->cname."\n"); 
                        }
                    }else{
                        print "Falló en ".$cnames." Tipo ".$p."\n#\n";
                    }
                }
            }
            when ("PTR") {
            }
            default {
                unless ($host =~ /in-addr.arpa/) {
                    print "Probando ".$host." Tipo ".$p."\n";
                    my $query = $res->query($host, $p);
                    if ($query) {
                        foreach ($query->answer) {
                            ok($_->mname, "Host: ".$host." - Tipo de Puntero: ".$p." - Respuesta ".$_->mname."\n") if ($p eq "SOA");
                            ok( ($_->nsdname ~~ @{$pointers->{$host}->{$p}}) || ($_->nsdname."." ~~ @{$pointers->{$host}->{$p}}), "Host: ".$host." - Tipo de Puntero: ".$p." - Respuesta ".$_->nsdname."\n") if ($p eq "NS");
                            ok($_->exchange, "Host: ".$host." - Tipo de Puntero: ".$p." - Respuesta ".$_->exchange."\n") if ($p eq "MX");
                            ok($_->address ~~ @{$pointers->{$host}->{$p}}, "Host: ".$host." - Tipo de Puntero: ".$p." - Repuesta: ".$_->address."\n") if ($p eq "A");
                            map { ok($_ ~~ $pointers->{$host}->{$p}, "Host: ".$host." - Tipo de Puntero: ".$p." - Respuesta ".$_."\n") } $_->char_str_list if ($p eq "TXT");
                        }
                    }else{
                        print "Falló en ".$host." Tipo ".$p."\n#\n";
                    }
                }
            }
        }
    }
}

sub get_public_zones {
    my ($pointers, $entrys) = @_;
    my @entrys = @$entrys; 

    #Recorriendo entradas en el LDIF
    foreach my $entry ( @entrys ) {
        if ( $entry->dn =~ /publicZones/ ) {
            $pointers = &build_hash($entry, $pointers);
        }
    }

    return $pointers;
}

sub get_privates_zones {
    my ($pointers, $entrys) = @_;
    my @entrys = @$entrys; 

    #Recorriendo entradas en el LDIF
    foreach my $entry ( @entrys ) {
        if ( $entry->dn =~ /privateZones/ ) {
            $pointers = &build_hash($entry, $pointers);
        }
    }

    return $pointers;
}

sub build_hash {
    my ($entry, $pointers) = @_;

    my @at;
    my @attrs =  $entry->attributes;
    foreach my $attr (@attrs) {
        if ( $entry->get_value("soarecord") ) {
            unless ( $attr ~~ @exclude_attrs) {
                given ($map_attr{$attr}) {
                    when ("TXT") {
                        my @var = map { s/["']//g; $_; } $entry->get_value($attr);
                        $pointers->{$entry->get_value("zonename")}->{$map_attr{$attr}} = [@var];
                    }
                    when ("MX") {
                        my $zone = $entry->get_value("zonename");
                        unless ( $entry->get_value($attr) =~ /\.$/) {
                            my @var = map { s/(\d*) (.*)/$2.$zone/g; $_; } $entry->get_value($attr);
                            $pointers->{$entry->get_value("zonename")}->{$map_attr{$attr}} = [@var];
                        }else{
                            my @var = map { s/(\d*) (.*)./$2/g; $_; } $entry->get_value($attr);
                            $pointers->{$entry->get_value("zonename")}->{$map_attr{$attr}} = [@var];
                        }
                    }
                    when ("NS") {
                        unless ( $entry->get_value($attr) =~ /\.$/) {
                            my $zone = $entry->get_value("zonename");
                            my @var = map { s/(.*)/$1.$zone/; $_; } $entry->get_value($attr);
                            $pointers->{$entry->get_value("zonename")}->{$map_attr{$attr}} = [@var];
                        }else{
                            $pointers->{$entry->get_value("zonename")}->{$map_attr{$attr}} = [$entry->get_value($attr)];
                        }
                    }
                    default {
                        $pointers->{$entry->get_value("zonename")}->{$map_attr{$attr}} = [$entry->get_value($attr)];
                    }
                }
                push (@at, $map_attr{$attr}) unless ($map_attr{$attr} ~~ @at );
                $pointers->{$entry->get_value("zonename")}->{"type_pointer"} = [@at];
            }
        } else {
            unless ( $attr ~~ @exclude_attrs) {
                given ($map_attr{$attr}) {
                    when ("CNAME") {
                        unless ( $entry->get_value($attr) =~ /\.$/) {
                            my $zone = $entry->get_value("zonename");
                            my @cnames = map {s/(.*$)/$1.$zone/; $_;} $entry->get_value($attr);
                            $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{$map_attr{$attr}} = [@cnames];
                        }else{
                            $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{$map_attr{$attr}} = [$entry->get_value($attr)];
                        }
                    }
                    when ("MX") {
                        unless ( $entry->get_value($attr) =~ /\.$/) {
                            my $zone = $entry->get_value("zonename");
                            my @var = map { s/(\d*) (.*)/$2.$zone/g; $_; } $entry->get_value($attr);
                            $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{$map_attr{$attr}} = [@var];
                        }else{
                            my @var = map { s/(\d*) (.*)/$2/g; $_; } $entry->get_value($attr);
                            $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{$map_attr{$attr}} = [@var];
                        }
                    }
                    when ("TXT") {
                        my $var = $entry->get_value($attr);
                        $var =~ s/["']//g;
                        $var =~ s/\s*$//g;
                        $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{$map_attr{$attr}} = $var;
                    }
                    when ("NS") {
                        unless ( $entry->get_value($attr) =~ /\.$/) {
                            my $zone = $entry->get_value("zonename");
                            my @var = map { s/(.*)/$1.$zone/; $_; } $entry->get_value($attr);
                            $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{$map_attr{$attr}} = [@var];
                        }else{
                            $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{$map_attr{$attr}} = [$entry->get_value($attr)];
                        }
                    }
                    default {
                        my @var = map { s/\s*$//; $_; } $entry->get_value($attr);
                        $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{$map_attr{$attr}} = [@var];
                    }
                }
                push (@at, $map_attr{$attr}) unless ($map_attr{$attr} ~~ @at );
                $pointers->{$entry->get_value("relativedomainname").".".$entry->get_value("zonename")}->{"type_pointer"} = [@at];
            }
        }
    }

    return $pointers;
}

sub read_ldif {
    my $ld = shift;

    my $ldif = Net::LDAP::LDIF->new( $ld, "r",  onerror => 'die' );

    my @entrys;
    
    while ( not $ldif->eof() ) {

        #Leyendo entrada del LDIF y guardandola en una lista
        push (@entrys, $ldif->read_entry());
        
    }

    $ldif->done();

    return @entrys;
}
