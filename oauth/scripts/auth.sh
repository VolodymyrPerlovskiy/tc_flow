#!/bin/bash

set -euo pipefail

usage="[start|stop|restart|dump|status]"

path_to_jar=${2:-undefined}
srv_port=${3:-undefined}
http_port=${4:-undefined}

export path_to_jar=$path_to_jar
export srv_port=$srv_port
export http_port=$http_port

echo $srv_port $http_port $path_to_jar

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

EXEC="java $mem -Dserver.port="${srv_port}" -Dserver.http.port="${http_port}" -jar "${path_to_jar}""

case "$1" in
        start)
         if [ ! -d log ]
         then
            pwd
            mkdir -p log
            ls -lah
         fi
         echo "Starting Auth-server"
         echo $usage $path_to_jar $srv_port $http_port
         DIR=`echo $path_to_jar | xargs dirname`
         cd $DIR
         pwd
         $EXEC >>log/auth-server.log &
         echo $! >$pid
        ;;
        stop)
         echo "Stoping Auth-server"
         echo $usage $path_to_jar $srv_port $http_port
         DIR=`echo $path_to_jar | xargs dirname`
         cd $DIR
         pwd
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
