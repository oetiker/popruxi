#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long 2.25 qw(:config posix_default no_ignore_case);
use Pod::Usage 1.14;
use Encode;
use autodie;

# main loop
my %opt = (
    quota => 512000000,
    days => 7,
    root => '.',
    domain => 'hin.ch',
);

sub main()
{
    # parse options

    GetOptions(\%opt, 'domain=s', 'help|h', 'man', 'noaction|no-action|n',
        'verbose|v','root=s','quota=s','days=s') or exit(1);
    if ($opt{help})     { pod2usage(1) }
    if ($opt{man})      { pod2usage(-exitstatus => 0, -verbose => 2) }
    if ($opt{noaction}) { die "ERROR: don't know how to \"no-action\".\n" }
    if (not @ARGV){
        pod2usage(1);
    }
    # print getAliases(@ARGV);
    for my $user (@ARGV){
        print c2z($user);
    }
}


main;

sub getAliases {
    my %uid = (map { $_ => 1 } @_);
    my $out = '';
    open my $ldif, '<', "$opt{root}/all_aliases_vaddress.txt";
    my $user;
    my $count=0;
    while (<$ldif>){
        chomp;
        /^dn:\s*uid=([^,]+),dc=hin,dc=ch/ && do {
            $user = $uid{$1} ? $1 : undef;
            $count = 0;
            next;
        };
        $user || next;
        /alias:\s*(\S+)/ && do {
            if ($user eq $1){
                warn "[$user] aliases itself. skipping\n";
                next;
            }
            warn "[$user] extra alias $1\n" if $count++ > 1;
            $out .= "addAccountAlias $user\@$opt{domain} $1\@$opt{domain}\n";
            next;
        };
        /vaddress:\s*(\S+)/ && do {
            warn "[$user] extra alias $1\n" if $count++ > 1;
            $out .= "addAccountAlias $user\@$opt{domain} $1\n";
            next;
        };
    }
    return  $out;
}
       


sub c2z {
    my ($user,$alias) = split /=/, shift,2;
    my $fl = substr($user,0,1);
    my $root = $opt{root};
    my %files = (
        notify_addr => "$root/notify/$fl/$user.addr",
        notify_msg => "$root/notify/$fl/$user.txt",
        quota => "$root/quota/$fl/user.$user",
        sieve => "$root/sieve/$fl/$user/filter.sieve.script",
    );

    my %convert = (
        notify_addr => sub {
            my $list = shift;
            if (scalar @$list > 1){
                warn "[$user] extra notification address $list->[1]\n";                            
            }        
            return  "modifyAccount $user zimbraPrefNewMailNotificationEnabled TRUE\n"
                  . "modifyAccount $user zimbraPrefNewMailNotificationAddress $list->[0]\n";
        },
        notify_msg => sub {
            my $msg = shift;
            my $message = join '${NEWLINE}', @$msg;
            $message =~ s{"}{\"}g;
            $message =~ s{\n}{\${NEWLINE}}g;
            return  decode("iso-8859-1","modifyAccount $user zimbraNewMailNotificationBody \"$message\"\n");
        },
        quota => sub {
            my $quota = shift->[1]*1024;         
            return $quota != $opt{quota} ? "modifyAccount $user zimbraMailQuota ".($quota)."\n" : '';
        },
        sieve => sub {
            my $msg = shift;
            my $cmd ='';
            my $first = 1;
            my $vacationMode = 0;
            my $vacationMsg = '';
            my $vacationEncoding = "iso-8859-1";
            for (@$msg){
                $vacationMode == 1 && /^Content-type:.+charset=(\S+)/ && do {
                    $vacationEncoding = $1;
                    next;
                };
                $vacationMode == 1 && /^$/ && do {
                    $vacationMode = 2;
                    next;                
                };
                $vacationMode > 0 && /^\.$/ && do {
                    $vacationMsg =~ s{"}{\"}g;
                    $vacationMsg =~ s{\n}{\\n}g;
                    $cmd .= "modifyAccount $user zimbraPrefOutOfOfficeReplyEnabled TRUE\n";
                    $cmd .= "modifyAccount $user zimbraPrefOutOfOfficeReply \"".decode($vacationEncoding,$vacationMsg)."\"\n";
                    $vacationMode = 0;
                    next;
                };
                $vacationMode == 2 && do {
                    $vacationMsg .= $_."\n";
                    next;
                };
                /^redirect\s+"(.+?)";$/ && do {
                    my $plus = $first ? '' : '+';
                    $first = 0;
                    $cmd .= "modifyAccount $user ${plus}zimbraMailForwardingAddress $1\n";
                    next;
                };
                /^vacation\s+:days\s+(\d+).+text:$/ && do {
                    $vacationMode = 1;
                    next if $1 == $opt{days};
                    $cmd .= "modifyAccount $user zimbraPrefOutOfOfficeCacheDuration ${1}d\n";
                    next;
                };                        
            }
            return $cmd;
        }
    );

    my $cmd = '';

    if ($alias){
        $cmd .= "addAccountAlias $user\@$opt{domain} $alias\n";
    }

    for my $key (keys %files){
        my $file = $files{$key};
        next unless -r $file;
        my @input;
        open my $fh, '<',$file;
        while (<$fh>){
            s/\r?\n$//;
            push @input,$_;
        };
        $cmd .= $convert{$key}->(\@input);
        close $fh;
    }
    return encode('utf8',$cmd);
}

__END__

=head1 NAME

cyrus2zmprov.pl - create zmprov lines based on hin cyrus config files

=head1 SYNOPSIS

B<cyrus2zmprov.pl> [I<options>...] I<user>[=I<alias@hin.ch>] [I<user>[=I<alias@hin.ch>] ...] > outupt.cfg

     --man           show man-page and exit
 -h, --help          display this help and exit
     --root=dir      where are the cyrus config files
     --days=x        default frequency for vacation message cache
     --quota=x       default mailquota in bytes
     --domain=hin.ch local domain (set to hin.ch by default)

=head1 DESCRIPTION

cyrus2zmprov.pl creates an input file for the zimbra command line
provisioning tool. The output of this script can be used like this:

 zmprov -f output.cfg

The script expects the cyrus config files in the following locations.
The root directory is the current directory by default (confiruable using the --root=x option).

 $root/notify/$fl/$user.addr
 $root/notify/$fl/$user.txt
 $root/quota/$fl/user.$user
 $root/sieve/$fl/$user/filter.sieve.script

=head1 BUGS

This program works only for sieve scripts that follow a specific pattern.

=head1 COPYRIGHT

Copyright (c) 2014 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2014-03-14 to Initial Version

=cut
