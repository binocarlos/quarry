#!/bin/sh
 
VERSION=0.8.6
PLATFORM=linux
ARCH=x64
PREFIX="$HOME/node-v$VERSION-$PLATFORM-$ARCH"
INSTALLATION="/usr/local"

mkdir -p "$PREFIX" && \
curl http://nodejs.org/dist/v$VERSION/node-v$VERSION-$PLATFORM-$ARCH.tar.gz \
  | tar xzvf - --strip-components=1 -C "$INSTALLATION"