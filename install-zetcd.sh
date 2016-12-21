#!/usr/bin/env bash
set -e

go get -v github.com/coreos/zetcd/cmd/zetcd
zetcd -h

echo "Done!"
