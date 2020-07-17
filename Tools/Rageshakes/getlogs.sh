#!/bin/sh

# ./getlogs.sh https://riot.im/bugreports/listing/2020-06-07/104229/

if [ ! $# -eq 1 ]; then
    echo "Usage: ./getLogs.sh [http link]"
    exit 1
fi 

LOGS_URL=$1

ID=$( basename $LOGS_URL )

echo $ID
mkdir $ID
cd $ID

wget -r -nd --user=matrix --password=a^njerkoo=les $LOGS_URL 

for f in *.log.gz; do 
    mv -- "$f" "${f%.log.gz}.log"
done

rm *.html

