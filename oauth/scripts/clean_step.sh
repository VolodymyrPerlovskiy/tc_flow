#!/bin/bash
echo "Post service deployment clean user home directory"
su - %env.username% -c 'ssh -o "StrictHostKeyChecking=no" "%env.username%@%env.deployment_server%"' <<'ENDSSH'
echo $USER
rm -r /home/%env.username%/%env.project%
rm -r /home/%env.username%/.ssh/
ENDSSH