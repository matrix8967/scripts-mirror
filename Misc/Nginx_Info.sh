#!/bin/bash
#Variable for Current Date.
c_date=$(date -u +"%d/%b/%Y")

# case insensitive match 'error' in nginx access.log and colorize output
echo -e "Case Insensitive match for error:"
grep -i error /var/log/nginx/error.log |ccze -A
echo -e "-----"
# how many 404 errors today?
echo -e "How many 404's today:"
grep "\" 404 " /var/log/nginx/access.log |grep "$c_date" |wc -l
echo -e "-----"
# what caused 404 errors, how many times did each one happen, and sort based on # times, and colorize
grep "\" 404 " /var/log/nginx/access.log |grep "$c_date" |cut -d \" -f 2 |sort |uniq -c |sort -rh |ccze -A
echo -e "-----"
# Total # of http requests
echo -e "Total http reqs:"
grep "$c_date" /var/log/nginx/access.log |wc -l
echo -e "-----"
# Total # of http requests that generated a 200 response code:
echo -e "Total http 200 return code:"
grep "$c_date" /var/log/nginx/access.log |grep "\" 200 " |wc -l
echo -e "-----"
# Total # of unique IPs:
echo -e "Total # of Unique IPs:"
grep "$c_date" /var/log/nginx/access.log |awk '{print $1}' |sort -u |wc -l
echo -e "-----"
# unique IPs today sorted by # of requests
echo -e "Unique IPs sorted by # of requests:"
grep "$c_date" /var/log/nginx/access.log |awk '{print $1}' |sort |uniq -c |sort -rh
echo -e "-----"
# top 20 referrer urls for today:
echo -e "Top 20 referrer URLs:"
grep $c_date /var/log/nginx/access.log |cut -d \" -f 4 |sort |uniq -c |sort -rh |head -20
echo -e "-----"
# top 20 webserver requests for today
echo -e "Top 20 webserver requests today:"
grep "$c_date" /var/log/nginx/access.log |cut -d \" -f 2 |sort |uniq -c |sort -rh |head -20
