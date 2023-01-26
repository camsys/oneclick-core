eval "$(ssh-agent -s)" #start the ssh agent
ssh-add cpta_aws.pem
git remote add deploy "ssh://ubuntu@occ-pa-dev-ec2.camsys-apps.com:/home/ubuntu/oneclick-core"
GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push deploy develop


