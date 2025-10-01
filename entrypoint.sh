#!/bin/bash
export LANG=C

# Save environment variables to a file that will be loaded when the MRTG cron job runs
echo "export LANG=C" > /tmp/env
echo "export TZ=$TZ" >> /tmp/env 

cleanup() {
        pids=`pgrep 'lighttpd|cron'`
        echo "`date +"%a %b %d %H:%M:%S %Y"` Shutting down lighttpd and cron..."
        while IFS= read -r line; do
                echo "killing pid: $line"
                kill $line
        done <<< "$pids"
        exit 0
}

echo "`date +"%a %b %d %H:%M:%S %Y"` Updating MRTG index..."
su - mrtg bash -c '/usr/bin/indexmaker /etc/mrtg/mrtg.cfg > /var/www/html/mrtg/index.html'

echo "`date +"%a %b %d %H:%M:%S %Y"` Starting lighttpd..."
lighttpd -f /etc/lighttpd/lighttpd.conf

echo "`date +"%a %b %d %H:%M:%S %Y"` Starting cron (to update mrtg data)..."
/usr/sbin/cron
tail -f /var/log/lighttpd/access.log &
trap cleanup SIGINT SIGKILL SIGTERM
wait

