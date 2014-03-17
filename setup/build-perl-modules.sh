#!/bin/bash

. `dirname $0`/sdbs.inc

for module in \
  Term::ReadKey \
  IO::Socket::SSL \
  Mail::POP3Client \
  DBI \
  DBD::SQLite \
  Mojolicious \
; do
  perlmodule $module
done

        
