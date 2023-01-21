#!/usr/bin/env bash

# check if we are in scripts folder
if [[ $PWD == *scripts ]]; then cd ..; fi

docker kill $(docker ps -q)

(cd ./backend/test && yarn) &
(cd ./seeds && yarn) &
(cd ./frontend && yarn) &

wait

(cd ./docker && docker compose up -d --build)
sh ./scripts/reset-all.sh