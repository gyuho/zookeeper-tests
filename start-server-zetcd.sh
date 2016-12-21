#!/usr/bin/env bash
set -e

echo "Starting etcd server..."
nohup ${GOPATH}/src/github.com/coreos/etcd/bin/etcd --name my-etcd-1 \
    --listen-client-urls http://localhost:2379 \
    --advertise-client-urls http://localhost:2379 \
    --listen-peer-urls http://localhost:2380 \
    --initial-advertise-peer-urls http://localhost:2380 \
    --initial-cluster my-etcd-1=http://localhost:2380 \
    --initial-cluster-token my-etcd-token \
    --initial-cluster-state new > ./etcd-server.log 2>&1 &

sleep 5s;

echo "Starting zetcd..."
nohup zetcd -zkaddr localhost:2181 -endpoint http://localhost:2379 > ./zetcd-server.log 2>&1 &
