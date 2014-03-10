#!/usr/bin/env perl

require 5.014;
use strict;
use Getopt::Long 2.25 qw(:config posix_default no_ignore_case);
use Pod::Usage 1.14;
use Term::ReadKey;
use Digest::SHA qw(hmac_sha256_hex);
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../thirdparty/lib/perl5";

use DBI;
use Mail::POP3Client;

# parse options
my %opt = ();

# main loop
sub main()
{
    my @mandatory = (qw(olduser=s oldpass=s oldserver=s newuser=s  newpass=s newserver=s dbfile=s));

    GetOptions(\%opt, 'help|h', 'man', 'noaction|no-action|n', @mandatory ) or exit(1);
    if($opt{help})     { pod2usage(1) }
    if($opt{man})      { pod2usage(-exitstatus => 0, -verbose => 2) }
    if($opt{noaction}) { die "ERROR: don't know how to \"no-action\".\n" }
    for my $key (map { s/=s//; $_ } @mandatory){
        if (not defined $opt{$key}){
            print STDERR $key.': ';
            ReadMode('noecho') if $key =~ /pass/;
            chomp($opt{$key} = <>);
            if ($key =~ /pass/){
                ReadMode(0);
                print STDERR "\n";
            }        
        }
    }

    # read the current state of the uid map
    my %uidmap;
    my $dbh = getDbh();
    print STDERR "* Load existing DB\n";
    
    my $sth = $dbh->prepare('select uid_new,uid_old,hash from uidmap where user = ?');
    $sth->execute($opt{newuser});
    my $uidmap;
    while (my ($uid_new,$uid_old,$hash) = $sth->fetchrow_array){
        $uidmap{new}{$uid_new} = $hash if $uid_new;
        $uidmap{old}{$uid_old} = $hash if $uid_old;
        $uidmap{old2new}{$uid_old} = $uid_new if $uid_old and $uid_new;
        $uidmap{hash2freenew}{$hash}{$uid_new} = 1 if not $uid_old;
        $uidmap{hash2freeold}{$hash}{$uid_old} = 1 if not $uid_new;
    }

    print STDERR "* Load Old UIDs from POP server\n";
    getUidlMap(\%uidmap,'old');
    print STDERR "* Load New UIDs from POP server\n";
    getUidlMap(\%uidmap,'new');

    # map old to new
    print STDERR "* Merge UIDs ";
    my $upd = $dbh->prepare('UPDATE uidmap SET uid_new = ? WHERE uid_old = ? AND user = ?');
    $dbh->begin_work;
    for my $uid_old (keys %{$uidmap{old}}){
        next if $uidmap{old2new}{$uid_old};
        my $hash = $uidmap{old}{$uid_old};
        for my $uid_new (keys %{$uidmap{hash2freenew}{$hash}}) {
            print STDERR ".";
            $upd->execute($uid_new,$uid_old,$opt{newuser});
            delete $uidmap{newnew}{$uid_new};
            last;
        }
    }
    $dbh->commit;
    print STDERR "\n";
    # record new hashes
    print STDERR "* Append new UIDs\n";
    my $ins = $dbh->prepare('INSERT INTO uidmap (uid_new,hash,user) VALUES (?,?,?)');
    $dbh->begin_work;
    for my $uid_new (keys %{$uidmap{newnew}}){        
        my $hash = $uidmap{new}{$uid_new};        
        $ins->execute($uid_new,$hash,$opt{newuser});
    }
    $dbh->commit;
}

sub getDbh {
    my $db = $opt{dbfile};
    my $dbExists = -s $db;
    my $dbh = DBI->connect_cached('dbi:SQLite:dbname='.$db,'','',{
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        FetchHashKeyName=>'NAME_lc',
    }) or die DBI->errstr();

    if (not $dbExists){
        $dbh->do(<<'SQL');
CREATE TABLE uidmap (
    user TEXT,
    uid_new TEXT,
    uid_old TEXT,
    hash TEXT
)
SQL
        $dbh->do('CREATE INDEX uid_new_idx ON uidmap (user,uid_new)');
        $dbh->do('CREATE INDEX hash_idx ON uidmap (user,hash)');
        $dbh->do('CREATE INDEX uid_old_idx ON uidmap (user,uid_old)');
    }    
    return $dbh;
}

sub getUidlMap {
    my $uidmap = shift;
    my $type = shift;

    my $pop = Mail::POP3Client->new( 
        HOST  => $opt{$type.'server'},
        USER => $opt{$type.'user'},
        PASSWORD => $opt{$type.'pass'},
        USESSL => 1,
        AUTH_MODE => 'PASS',
    );
    if ($pop->Message !~ /OK/){
        die "Problem: ".$pop->Message()."\n";
    }

    my $dbh = getDbh();
    my $ins = $dbh->prepare('INSERT INTO uidmap (user,uid_old,hash) VALUES (?,?,?)');

    my $id = 0;
    my $count = $pop->Count;
    my @uidl = $pop->Uidl;


    $dbh->begin_work;    
    for (my $id=1;$id<=$count;$id++){        
        my $uid = $uidl[$id] or next;
#        print STDERR $id," \r" if $id % 10 == 1;
        if ( not $uidmap->{$type}{$uid} ){
            print STDERR $uid,"\n";
            my @headers = sort grep /^(From|To|Message-Id|Subject|Date):/i, $pop->Head( $id );            
            my  $hash = hmac_sha256_hex(join '\n', @headers );
#           warn $hash,"\n";
#           warn Dumper [sort @headers];
            # add missing
            if ($type eq 'old'){
                $ins->execute($opt{newuser},$uid,$hash);
            }
            else {
                $uidmap->{hash2freenew}{$hash}{$uid} = 1;
                $uidmap->{newnew}{$uid} = 1; # these are not in the db yet
            }
            $uidmap->{$type}{$uid}=$hash;
        }
    }
    $dbh->commit;
}

main;

__END__

=head1 NAME

template_tool - ISGTC tool template

=head1 SYNOPSIS

B<template_tool> [I<options>...]

     --man           show man-page and exit
 -h, --help          display this help and exit
     --version       output version information and exit

=head1 DESCRIPTION

Very useful hello-world application... With a magic marker
##ISGTC_MAGIC_SYSCONFDIR##.

=head1 COPYRIGHT

Copyright (c) 2006 by ETH Zurich. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<David Schweikert E<lt>dws@ee.ethz.chE<gt>>

=head1 HISTORY

 2006-XX-XX ds Initial Version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
