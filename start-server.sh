#!/usr/bin/env bash
set -e

echo "Cleaning up Zookeeper data directory..."
DATA_DIR=./zookeeper/data.zk
rm -rf ${DATA_DIR}
mkdir -p ${DATA_DIR}

sleep 2s
echo "Writing myid file..."
cat > ${DATA_DIR}/myid <<EOF
1
EOF

sleep 2s
echo "Writing config file..."
cat > ./zookeeper/zookeeper.config <<EOF
tickTime=2000
dataDir=./zookeeper/data.zk
clientPort=2181
initLimit=5
syncLimit=5
maxClientCnxns=5000
snapCount=100000
server.1=localhost:2888:3888
EOF

sleep 2s
echo "Starting Zookeeper..."
cd ./zookeeper
nohup java -cp zookeeper-3.4.9.jar:lib/slf4j-api-1.6.1.jar:lib/slf4j-log4j12-1.6.1.jar:lib/log4j-1.2.16.jar:conf org.apache.zookeeper.server.quorum.QuorumPeerMain ./zookeeper/zookeeper.config > ../zookeeper-server.log 2>&1 &

sleep 3s
echo "Done"
cat ../zookeeper-server.log

