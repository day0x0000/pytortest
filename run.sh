#!/bin/bash
sudo service xvfb start
export DISPLAY=:10

echo
echo "Waiting for tor proxy to become ready ..."
while ! nc -z localhost 9050; do
  sleep 5
  echo .
done
echo "Tor proxy: ready"

while ! /usr/bin/env python ./test.py tor-browser_en-US ./output "$@"; do
  echo "retrying..."
done
echo "ok"

# read  -n 1 -p "Input Selection:" mainmenuinput
