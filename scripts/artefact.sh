#!/bin/bash
echo "Update OS repo"
apt update && apt-get -f install sshpass gcp
# Add a user to Linux system
adduser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password --force-badname
echo "Switch user"
su - %env.username% -c 'rm -f /home/%env.username%/.ssh/*'
echo "Generate key pair"
su - %env.username% -c 'ssh-keygen -t rsa -f /home/%env.username%/.ssh/id_rsa -q -P ""'
echo "Copy ssh key to remote server"
su - %env.username% -c 'sshpass -p "%env.user_password%" ssh-copy-id -o StrictHostKeyChecking=no %env.username%@%env.deployment_server%'
echo "Create folders for service deployment as sudo user"
su - %env.username% -c 'ssh -T -o "StrictHostKeyChecking=no" "%env.username%@%env.deployment_server%"' <<'ENDSSH'
sudo su - sab
echo $USER
echo %env.app_name%
mkdir -p /app/uat/%env.team%/%env.project%
mkdir -p /app/uat/%env.team%/%env.project%/%env.branch%/
ENDSSH
echo "Create folders structure in maintainer home directory"
su - %env.username% -c 'ssh -T -o "StrictHostKeyChecking=no" "%env.username%@%env.deployment_server%"' <<'ENDSSH'
mkdir -p /home/%env.username%/%env.project%/%env.branch%
mkdir -p /home/%env.username%/%env.project%/%env.branch%/config
mkdir -p /home/%env.username%/%env.project%/%env.branch%/public
ENDSSH
echo "Secure copy artefact to ENV server"
su - %env.username% -c 'scp -rp "%teamcity.build.checkoutDir%/assembly/%env.app_name%/"'*'".jar" %env.username%@%env.deployment_server%:"/home/%env.username%/%env.project%/%env.branch%"'
su - %env.username% -c 'scp -rp "/opt/buildagent/work/"'*'".sh" %env.username%@%env.deployment_server%:"/home/%env.username%/%env.project%/%env.branch%"'
su - %env.username% -c 'scp -rp "%teamcity.build.checkoutDir%/config" %env.username%@%env.deployment_server%:"/home/%env.username%/%env.project%/%env.branch%/"'
su - %env.username% -c 'scp -rp "%teamcity.build.checkoutDir%/public" %env.username%@%env.deployment_server%:"/home/%env.username%/%env.project%/%env.branch%/"'
echo "Move artifact and config files into target directory"
su - %env.username% -c 'ssh -T -o "StrictHostKeyChecking=no" "%env.username%@%env.deployment_server%"' <<'ENDSSH'
sudo su - sab
echo $USER
cp -rf /home/%env.username%/%env.project%/%env.branch%/* /app/uat/%env.team%/%env.project%/%env.branch%/
sh /app/uat/%env.team%/%env.project%/%env.branch%/auth.sh stop
sh /app/uat/%env.team%/%env.project%/%env.branch%/auth.sh start %env.server_port% %env.http_server_port%
ENDSSH