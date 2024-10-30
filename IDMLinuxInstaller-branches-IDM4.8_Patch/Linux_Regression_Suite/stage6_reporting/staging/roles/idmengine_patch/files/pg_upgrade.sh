#!/usr/bin/expect -f
#!/bin/bash

cd /mnt/common/scripts
set timeout -1
spawn ./pg-upgrade.sh
match_max 100000
expect -exact "\r
Enter Existing Postgres install location \[/opt/netiq/idm/postgres\] : "
send -- "\r"
expect -exact "\r
\r
Enter Existing Postgres Data Directory \[/opt/netiq/idm/postgres/data\] : "
send -- "\r"
expect -exact "\r
\r
Enter Existing Postgres Database password : "
send -- "novell\r"
expect eof