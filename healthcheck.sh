#!/bin/bash

# return 0 if there are mrtg files less than 10 minuts old, otherwise return 1
if [[ `find /var/www/html/mrtg -mmin -10 | wc -l` -ge 1 ]] ; then 
        exit 0
else 
        exit 1
fi

