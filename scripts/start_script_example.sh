#!/bin/bash

set -ue

usage="[start|stop|restart|dump]"

if [ $# -eq 0 ]
then
    echo $usage
    exit
fi

pid=sab.pid
mem=-Xmx128m
port=-Dsab.port=7080

PROXY_HOST=127.0.0.1
PROXY_PORT=3128
PROXY="-Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT" #настройки тестового сервера разработчиков
PROXY="" #не использовать прокси (если нужно вкл. проксю, удалить эту строку и исправить хост/порт

CLASSPATH=sab.jar

for a in `ls lib/*`; do
CLASSPATH=$CLASSPATH:$a
done;

EXEC="java $mem $port $PROXY -classpath $CLASSPATH sab.Main"

case $1 in
     start)
         if [ ! -d log ]
         then
            mkdir log
         fi
         echo "Starting SAB"
         nohup $EXEC 2>1 1>/dev/null &
         echo $! >$pid
     ;;
     stop)
         echo "Stoping SAB"
         kill `cat $pid`
         rm $pid
         sleep 5
     ;;
     restart)
         ./sab.sh stop
         ./sab.sh start
     ;;
     deploy)
         if [ -f $pid ];
            then
                echo "SAB running"
                ./sab.sh stop
            else
                echo "SAB not running"
         fi
         ./sab.sh start
     ;;
     dump)
         kill -QUIT `cat $pid`
         echo 'JVM thread dump created in log/sab.out'
         jmap -dump:live,format=b,file=heap.bin `cat $pid`
     ;;
     *) echo "$0 $usage";;
esac