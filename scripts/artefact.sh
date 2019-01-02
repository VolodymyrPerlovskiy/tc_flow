#!/usr/bin/bash
echo "Update OS repo"
#apt update && apt install sshpass
# Add a user to Linux system
adduser v.perlovskiy --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password --force-badname
echo "Switch user"
su - v.perlovskiy -c 'rm -f /home/v.perlovskiy/.ssh/*'
echo "Generate key pair"
su - v.perlovskiy -c 'ssh-keygen -t rsa -f /home/v.perlovskiy/.ssh/id_rsa -q -P ""'
echo "Copy ssh key to remote server"
su - v.perlovskiy -c 'sshpass -p "&Wa#4cIfX@" ssh-copy-id -o StrictHostKeyChecking=no v.perlovskiy@ddigitapu02.alfa.bank.int'
echo "Secure copy artefact to ENV server"
su - v.perlovskiy -c 'scp -rpv "/opt/buildagent/work/7b2e9c98288f4577/target/"'*'".jar" v.perlovskiy@ddigitapu02.alfa.bank.int:"/home/v.perlovskiy/teamcity"'
su - v.perlovskiy -c 'scp -rpv "/opt/buildagent/work/7b2e9c98288f4577/target/"'*'".sh" v.perlovskiy@ddigitapu02.alfa.bank.int:"/home/v.perlovskiy/teamcity"'
su - v.perlovskiy -c 'scp -rp "/opt/buildagent/work/7b2e9c98288f4577/config" v.perlovskiy@ddigitapu02.alfa.bank.int:"/home/v.perlovskiy/teamcity/config"'
su - v.perlovskiy -c 'scp -rp "/opt/buildagent/work/7b2e9c98288f4577/public" v.perlovskiy@ddigitapu02.alfa.bank.int:"/home/v.perlovskiy/teamcity/public"'
