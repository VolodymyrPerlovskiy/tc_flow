#!/bin/bash

set -euo pipefail

usage="[start|stop|restart|dump|status]"

srv_port=${2:-undefined}
http_port=${3:-undefined}

export srv_port=$srv_port
export http_port=$http_port

echo $srv_port $http_port

for n in $@
do
  echo "$n"
done

if [ $# -eq 0 ]
then
    echo $usage
    exit
fi

pid=auth-server.pid
mem=-Xmx64m

EXEC="java $mem -Dserver.port="${srv_port}" -Dserver.http.port="${http_port}" -jar ./auth-server*.jar"

case "$1" in
        start)
         if [ ! -d log ]
         then
            pwd
            mkdir -p log
            ls -lah
         fi
         echo "Starting Auth-server"
         echo $usage $srv_port $http_port
         cd /app/uat/5_dev_ops/auth-server/feature/
         pwd
         $EXEC >auth-server.log &
         echo $! >$pid
        ;;
        stop)
         echo "Stoping Auth-server"
         echo $usage $srv_port $http_port
         cd /app/uat/5_dev_ops/auth-server/feature/
         kill `cat $pid`
         rm $pid
         sleep 5
        ;;
        restart)
         auth.sh stop
         auth.sh start
         kill -QUIT `cat $pid`
         jmap -dump:live,format=b,file=heap.bin `cat $pid`
        ;;
 *)
    echo "$0 $usage"
esac
