#!/bin/bash
echo "<h1>Hello, World</h1>" > index.html
echo "<p>DB address: ${db_address}</p>" >> index.html
echo "<p>DB port: ${db_port}</p>" >> index.html
nohup busybox httpd -f -p ${server_port} &
