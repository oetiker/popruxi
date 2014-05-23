package Popruxi::PopClient;

use Mojo::Base -base;

use Mojo::IOLoop;
use DBI;
use Popruxi::Util qw(eatBuffer);

use Scalar::Util 'weaken';

has state => sub {
    {}
};

has 'app';

has 'clientId';

has cfg => sub {
    shift->app->cfg;
};

has log => sub {
    shift->app->log;
};

has port => sub {
    shift->cfg->{serverport};
};

has host => sub {
    shift->cfg->{server}
};


has id => sub {
    die "Call start first";
};

sub start {
    my $self = shift;
    $self->id(Mojo::IOLoop->client(
        {address => $self->host, port => $self->port} => $self->connectionSetup
    ));
    return $self;
};

has sthUidOld => sub {
    my $self = shift;
    $self->dbh->prepare('SELECT uid_old FROM uidmap WHERE uid_new = ? AND user = ?');
};

has reader => sub {
    my $self = shift;
    my $serverBuffer;
    my $state = $self->state;
    my $clientId = $self->clientId;
    my $dbh = $self->dbh;
    my $sthUidOld = $self->sthUidOld;
    weaken $self;
    sub {
        my ($serverStream, $chunk) = @_;
        $serverBuffer .= $chunk;
        my $reply = '';
        my $lines;
        my $nl;
        ($lines,$nl,$serverBuffer) = eatBuffer($serverBuffer);
        for my $line (@$lines){
            if ($state->{EXPECTING_UIDL}){
                if ($line eq '.'){
                    $state->{EXPECTING_UIDL} = 0;
                    $reply .= $line.$nl;
                }
                elsif ($line =~ m/^(\d+)\s+(\S+)$/){
                    my $id = $1;
                    my $uid_new = $2;
                    # is might be faster to delay the answer and lookup all the uids in one go
                    # using an array ... 
                    $reply .= $id.' ';
                    if (my $uid_old = $dbh->selectrow_array($sthUidOld,{},$uid_new,$state->{USER})){
                        $reply .= $uid_old;
                    }
                    else {
                        $reply .= $uid_new;
                    }
                    $reply .= $nl;
                }
                else {
                    $reply .= $line.$nl;  
                }
            }
            else {
                $reply .= $line.$nl;
            }
        }
        if (my $clientStream = Mojo::IOLoop->stream($clientId)){
            $clientStream->write($reply);
        }
        else {
            $self->log->error("client quit unexpectedly");
            Mojo::IOLoop->remove($clientId);
        }
    }
};

has connectionSetup => sub {
    my $self = shift;
    my $log = $self->log;
    weaken $self;
    sub {
        my ($loop, $err, $serverStream) = @_;
        # Connection to server failed
        if ($err) {
            $log->error("Connection error for ".$self->host.":".$self->port.": $err");
            Mojo::IOLoop->remove($self->clientId);
            return;
        }
        # Start forwarding data in both directions
        $log->info("Forwarding to ".$self->host.":".$self->port);
        # Server closed connection so we end it with the client too
        $serverStream->on(
            close => sub {
                Mojo::IOLoop->remove($self->clientId);
            }
        );
        $serverStream->on( read => $self->reader );
        $serverStream->on( error => sub {
            my ($stream, $err) = @_;
            $log->info("Server error $err");
            Mojo::IOLoop->remove($self->clientId);
        });
    };
};

has dbh => sub {
    my $self = shift;
    my $dbh = DBI->connect_cached('dbi:SQLite:dbname='.$self->cfg->{dbfile},'','',{
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        FetchHashKeyName=>'NAME_lc',
    }) or do {
        $self->log->error(DBI->errstr());
        die DBI->errstr();
    };
    return $dbh;
};

sub DESTROY {
    my $self = shift;
    $self->log->debug('pop client instance '.$self->host.' destroyed -- good -- no leak');
}

1;

__END__

=head1 NAME

Popruxi::PopClient - pop uid proxy client

=head1 SYNOPSIS

    use Popruxi::PopClient;
    ...
    my $client = Popruxi::PopClient->new(app=>$self->app,clientId=>$clientId);
    ...

=head1 DESCRIPTION

This client connects to the real pop server and watches out for UIDL list.
It replaces UIDs if necessary

=head1 ATTRIBUTES

=head2 app

our master

=head2 cfg

the config map by default from the app.

=head2 log

the log object.by default from the app.

=head2 port

the liste port to connect to on the pop server. populated via cfg serverport

=head2 host

the pop server to connect to populated via cfg server

=head2 clientId

the IOLoop id of the client connection

=head2 id 

the ioloop id of the client. only available after calling the start method.

=head2 reader

returns a function pointer for processing the output from the pop server
it handles the UID replacement.

=head2 connectionSetup

returns a function pointer for setting up the connection.

=head1 METHODS

=head2 start

insert the client into the ioloop. returns self so you can call it chained after new.

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
