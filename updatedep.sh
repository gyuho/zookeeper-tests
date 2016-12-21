#!/usr/bin/env bash

# A script for updating godep dependencies for the vendored directory /cmd/
# without pulling in etcd itself as a dependency.
#
# update depedency
# 1. edit glide.yaml with version, git SHA
# 2. run ./updatedep.sh
# 3. it automatically detects new git SHA, and vendors updates to cmd/vendor directory
#
# add depedency
# 1. run ./updatedep.sh github.com/USER/PROJECT#^1.0.0
#        OR
#        ./updatedep.sh github.com/USER/PROJECT#9b772b54b3bf0be1eec083c9669766a56332559a
# 2. make sure glide.yaml and glide.lock are updated

rm -rf vendor

GLIDE_ROOT="$GOPATH/src/github.com/Masterminds/glide"
GLIDE_SHA=21ff6d397ccca910873d8eaabab6a941c364cc70
go get -d -u github.com/Masterminds/glide
pushd "${GLIDE_ROOT}"
	git reset --hard ${GLIDE_SHA}
	go install
popd

GLIDE_VC_ROOT="$GOPATH/src/github.com/sgotti/glide-vc"
GLIDE_VC_SHA=d96375d23c85287e80296cdf48f9d21c227fa40a
go get -d -u github.com/sgotti/glide-vc
pushd "${GLIDE_VC_ROOT}"
	git reset --hard ${GLIDE_VC_SHA}
	go install
popd

if [ -n "$1" ]; then
	echo "glide get on $(echo $1)"
	matches=`grep "name: $1" glide.lock`
	if [ ! -z "$matches" ]; then
		echo "glide update on $1"
		glide update --strip-vendor $1
	else
		echo "glide get on $1"
		glide get --strip-vendor $1
	fi
else
	echo "glide update on *"
	glide update --strip-vendor
fi;

echo "removing test files"
glide vc --only-code --no-tests

echo "done"

