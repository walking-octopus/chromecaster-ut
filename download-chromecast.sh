#!/bin/bash

ARCH="$1";
SOURCE_DIR="$2"

GOOS=linux

case $ARCH in
    "armhf" )
        GOARCH=arm;
        GOARM=6;;
    "arm64" )
        GOARCH=arm;
        GOARM=7;;
    "amd64" )
        GOARCH="amd64";;
    * )
        echo "$ARCH doesn't have nodeJS version"; exit;;
esac

rm -rf go-chromecast
git clone https://github.com/vishen/go-chromecast.git
cd go-chromecast
go build -o ../install/go-chromecast
