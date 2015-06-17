package Popruxi::Proxy;

use Mojo::Base -base;

use Mojo::IOLoop;
use Popruxi::Util qw(eatBuffer);
use Popruxi::PopClient;

has 'app';

has cfg => sub {
    shift->app->cfg;
};

has log => sub {
    shift->app->log;
};
has port => sub {
    my $self = shift;
    $self->cfg->{listenport};
};

sub userInputHandler {
    my $self = shift;
    my $popruxiClient = shift;
    my $state = $popruxiClient->state;
    sub {
        my ($clientStream, $chunk) = @_;
        $state->{data} .= $chunk;
        my $lines;
        my $nl;
        ($lines,$nl,$state->{data}) = eatBuffer($state->{data});
        for my $line (@$lines){
            if (!$state->{USER} and $line =~ /USER\s+(\S+)/i){
                $state->{USER}=$1;
            }
            if ($line =~ /^UIDL/i){
                $state->{EXPECTING_UIDL}=1;
            }
            else {
                $state->{EXPECTING_UIDL}=0;
            }
        }
        if (my $serverStream = Mojo::IOLoop->stream($popruxiClient->id)){
            $serverStream->write($chunk);
        }
        else {
            $self->log->error("upstream server quit unexpectedly");
            Mojo::IOLoop->remove($popruxiClient->id);
        }
    }
}

has connectionHandler => sub {
    my $self = shift;
    sub {
        my ($loop, $clientStream, $clientId) = @_;
        my $state = {};
        my $handle = $clientStream->handle;
        $self->log->debug("Connection from ".$handle->peerhost.':'.$handle->peerport);
        # oh hello client ... lets quickly open a connection to the server
        my $popruxiClient = Popruxi::PopClient->new(app=>$self->app,clientId=>$clientId)->start;
        $clientStream->on(read => $self->userInputHandler($popruxiClient));
        $clientStream->on(close => sub {
            $self->log->debug("Client quit from ".$handle->peerhost.':'.$handle->peerport);
            Mojo::IOLoop->remove($popruxiClient->id);
        });
        $clientStream->on(error => sub {
            my ($stream, $err) = @_;
            $self->log->warn("Client error $err from ".$handle->peerhost.':'.$handle->peerport);
            Mojo::IOLoop->remove($popruxiClient->id);
        });
    }
};

# the id of this server
has id => sub {
    die "first call start";
};

sub start {
    my $self = shift;
    $self->id(Mojo::IOLoop->server(
        {port => $self->cfg->{listenport}} => $self->connectionHandler
    ));
    return $self;
}
1;

__END__

=head1 NAME

Pod::Proxy - pop proxy server

=head1 SYNOPSIS

    use Popruxi::Proxy;
    my $popruxi = Popruxi::Proxy->new(cfg=>\%cfg);
    my $serverId = $popruxi->id;
    Mojo::IOLoop->run;

=head1 DESCRIPTION

Start a pop server proxy

=head1 ATTRIBUTES

=head2 app

our master

=head2 cfg

the config map by default from the app.

=head2 log

the log object.by default from the app.

=head2 port

the liste port gets set from the cfg maps C<listenport> property.

=head2 connectionHandler

returns a function pointer to get called when a new client connects

=head2 id

our id in the IO loop. only available after calling start.

=head1 METHODS

=head2 start

insert the server into the ioloop. returns self so you can call it chaned after new.

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
