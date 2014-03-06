package Popruxi::Util;

use Mojo::Base -strict;

use Exporter qw(import);

our @EXPORT_OK = qw(eatBuffer);

sub eatBuffer {
    my @data = split /(\x0d?\x0a)/, shift;
    my @response;
    my $nlr;
    my $line;
    while (@data){
        $line = shift @data;
        my $nl = shift @data;
        if ($nl){
            $nlr ||= $nl;
            push @response, $line;
            $line = '';
        }
    }
    return (\@response,$nlr,$line);    
}

__END__

=head1 NAME

Popruxi::Util - some helper functions for Popruxi

=head1 SYNOPSIS

  use Popruxi::Util qw(eatBuffer);
  my ($lines,$nl,$buffer) = eatBuffer($buffer);

=head1 DESCRIPTION

Some helper functions

=head2 ($lines,$nl,$rest) = eatBuffer($buffer)

Split a buffer into C<\r?\n> separated lines. If the last line
does not end in C<\r?\n> return it separately.

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
