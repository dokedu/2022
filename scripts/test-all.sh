#!/usr/bin/env bash

# check if we are in scripts folder
if [[ $PWD == *scripts ]]; then cd ..; fi

pids=""
(cd backend && export GO_ENV=test && pwd && go test -race ./...) & pids+=" $!"
(set -o pipefail && cd backend/test && yarn run test | tee /dev/null) & pids+=" $!"
(cd frontend && (yarn dev & echo $! > /tmp/dokedu.yarnPid) && sleep 2 && yarn run cypress:run) & pids+=" $!"

err=""
for p in $pids; do
        if ! wait "$p"; then
          err+=" $p"
        fi
done

kill "$(cat /tmp/dokedu.yarnPid)"
rm /tmp/dokedu.yarnPid

if [ -n "$err" ]; then
  echo "error in pid $err"
  exit 1
fi

echo "✔  All tests passed!"