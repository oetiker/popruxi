package Popruxi;

use Mojo::Base -base;
use Popruxi::Proxy;
use Mojo::Log;

use Mojo::IOLoop;

has log => sub {
    my $self = shift;
    Mojo::Log->new(
        path => $self->cfg->{logpath} || '/dev/stderr',
        level => $self->cfg->{loglevel} || 'debug',
    );
};

has cfg => sub {
    {
        listenport => 3110,
        serverport => 110,
    }  
};

our $VERSION = '1.13';

sub run {
    my $self = shift;
    $self->log->info('Starting popruxi '.$VERSION);
    Popruxi::Proxy->new(app=>$self)->start;
    # Start event loop
    Mojo::IOLoop->start;
}

1;

__END__

=head1 NAME

Popruxi - pop uid proxy

=head1 SYNOPSIS

    use Popruxi;
    my $pud = Pud->new();
    my $cfg = $pud->cfg;
    $pud->run;

=head1 DESCRIPTION

Start a pop server proxy

=head1 ATTRIBUTES

=head2 cfg

the config hash

=head2 log

the logger object

=head1 METHODS

=head2 run

start the proxy

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
