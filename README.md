popruxi.pl
==========
pop proxy with uid mapping ability

SYNOPSIS
--------
propruxi.pl [*options*...]

    --man           show man-page and exit
    --help          display this help and exit
    --version       output version information and exit
    --server=x      upstream pop server
    --serverport=x  port on upstream pop server
    --listenport=x  on which port should we be listening
    --dbfile=x      where is the uid database

DESCRIPTION
-----------
When migrating a pop server to a new host, the message uids will normally
change. This causes all clients to re-download all their mail after the
change.

This proxy is able to replace message uids as reported by the "UIDL" command
based on a list stored in an sqlite database.

COPYRIGHT
---------
Copyright (c) 2014 by OETIKER+PARTNER AG. All rights reserved.

LICENSE
-------
This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.
