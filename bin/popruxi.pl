#!/usr/bin/env perl

use Getopt::Long 2.25 qw(:config posix_default no_ignore_case);
use Pod::Usage 1.14;
use Term::ReadKey;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../thirdparty/lib/perl5";


use Mojo::Base -strict;
use Popruxi;

# main loop
sub main {
    my $popruxi = Popruxi->new();
    my $opt = $popruxi->cfg;
    my @mandatory = (qw(server=s serverport=s listenport=s dbfile=s));

    GetOptions($opt, 'help|h', 'man', 'noaction|no-action|n', @mandatory ) or exit(1);

    if($opt->{help})     { pod2usage(1) }
    if($opt->{man})      { pod2usage(-exitstatus => 0, -verbose => 2) }
    if($opt->{noaction}) { die "ERROR: don't know how to \"no-action\".\n" }

    for my $key (map { s/=s//; $_ } @mandatory){
        if (not defined $opt->{$key}){
            print STDERR $key.': ';
            ReadMode('noecho') if $key =~ /pass/;
            chomp($opt->{$key} = <>);
            if ($key =~ /pass/){
                ReadMode(0);
                print STDERR "\n";
            }        
        }
    }
    say "Waiting for connections on port ".$popruxi->cfg->{listenport};
    $popruxi->run;
}

main;

__END__

=head1 NAME

popruxi.pl - pop proxy with uid mapping ability

=head1 SYNOPSIS

B<propruxi.pl> [I<options>...]

    --man           show man-page and exit
 -h,--help          display this help and exit
    --version       output version information and exit
    --server=x      upstream pop server
    --serverport=x  port on upstream pop server
    --listenport=x  on which port should we be listening
    --dbfile=x      where is the uid database

=head1 DESCRIPTION

When migrating a pop server to a new host, the message uids will normally
change. This causes all clients to re-download all their mail after the change.

This proxy is able to replace message uids as reported by the C<UIDL> command
based on a list stored in an sqlite database.

=head1 COPYRIGHT

Copyright (c) 2014 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2014-03-06 to Initial Version

=cut
