#!/bin/bash

# Credit: http://poormansprofiler.org/

nsamples=100
sleeptime=0
pid=$(pidof mysqld)

for x in $(seq 1 $nsamples)
  do
    gdb -ex "file build/app-redis_kvm-x86_64.dbg" \
        -ex "set arch i386:x86-64" \
        -ex "target remote localhost:1234" \
        -ex "set pagination 0" \
        -ex "thread apply all bt" \
        --batch
    sleep $sleeptime
  done | \
awk '
  BEGIN { s = ""; } 
  /^Thread/ { print s; s = ""; } 
  /^\#/ { if (s != "" ) { s = s "," $4} else { s = $4 } } 
  END { print s }' | \
sort | uniq -c | sort -r -n -k 1,1