Popruxi
=======
POP3 proxy with uid mapping ability

Use Case
--------
When migrating POP accounts from one server to another one, the unique IDs
of the POP messages do normally change.  For people who use their POP
accounts with 'leave on server' active this will cause all existing messages
to suddenly appear a second time in thier inbox.

The reason for this is, that POP clients use the command UIDL to retreive a
list of unique ids for all the messages stored on the server.  By comparing
this list with the list for the messages already received, they decide which
messages they have to download from the POP server.

When switching server products, the UIDL command will normally return all
new unique ids for the existing messages.

With Popruxi the list of UIDs can be synced from the old server. The POP
proxy service will then on the fly replace the unique ids from the new
server with ids from the old server.


Installation
------------

    $ cd /opt
    $ git clone https://github.com/oetiker/popruxi
    $ cd popruxi
    $ ./setup/build-perl-modules.sh

Usage
-----

First you have to sync the accounts you have migrated

    $ ./bin/uidmatcher.pl --olduser xxx --oldserver old.xxx.yyy --oldpass=sf83j \
      --newserver new.xxx.yyy --newuser xxx --newpass asfoilkjhasf \
      --dbfile /opt/popruxi/uidmap.db
    
Second you can run the pop proxy server

    $ ./bin/popruxi.pl --server new.xxx.yyy --dbfile /opt/popruxi/uidmap.db


