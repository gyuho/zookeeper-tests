#!/usr/bin/env bash
set -e

echo "Installing zookeeper-tests..."
go install -v

echo "Starting tests..."
nohup zookeeper-tests -clients 1000 -endpoints localhost:2181 -key-size 8 -val-size 256 -writes 2000000 > ./zookeeper-tests-result.txt 2>&1 &

