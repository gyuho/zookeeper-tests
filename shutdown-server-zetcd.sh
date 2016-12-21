#!/usr/bin/env bash
set -e

for PORT in 2181 2379 2380; do
    echo "SIGINT to" ${PORT}
    if [ -n "$(lsof -ti tcp:${PORT})" ]; then
        kill -2 $(lsof -ti tcp:${PORT})
        echo "Killed" ${PORT}
    else
        echo ${PORT} "has no processes"
    fi
done

for PORT in 2181 2379 2380; do
    echo "SIGKILL to" ${PORT}
    if [ -n "$(lsof -ti tcp:${PORT})" ]; then
        kill -9 $(lsof -ti tcp:${PORT})
        echo "Killed" ${PORT}
    else
        echo ${PORT} "has no processes"
    fi
done
