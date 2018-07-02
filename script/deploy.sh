#!/bin/sh

set -e

openssl aes-256-cbc -K $encrypted_d4913dfcf832_key -iv $encrypted_d4913dfcf832_iv -in github_deploy_key.enc -out github_deploy_key -d
chmod 600 github_deploy_key
eval $(ssh-agent -s)
ssh-add github_deploy_key

bundle install
rake ci:tag
