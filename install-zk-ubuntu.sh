#!/usr/bin/env bash
set -e

echo "Installing Java..."
sudo apt-get -y --allow-unauthenticated install ansible

cat > /tmp/install-java.yml <<EOF
---
- name: a play that runs entirely on the ansible host
  hosts: localhost
  connection: local
  tasks:
  - name: Install Linux utils
    become: yes
    apt: name={{item}} state=latest
    with_items:
      - bash
      - curl
      - git
      - tar
      - iptables
      - iproute2
      - unzip

  - name: Install add-apt-repostory
    become: yes
    apt: name=software-properties-common state=latest

  - name: Add Oracle Java Repository
    become: yes
    apt_repository: repo='ppa:webupd8team/java'

  - name: Accept Java 8 License
    become: yes
    debconf: name='oracle-java8-installer' question='shared/accepted-oracle-license-v1-1' value='true' vtype='select'

  - name: Install Oracle Java 8
    become: yes
    apt: name={{item}} state=latest
    with_items:
      - oracle-java8-installer
      - ca-certificates
      - oracle-java8-set-default

  - name: Print Java version
    command: java -version
    register: result
  - debug:
      var: result.stderr

  - name: Print JDK version
    command: javac -version
    register: result
  - debug:
      var: result.stderr
EOF
ansible-playbook /tmp/install-java.yml

java -version
javac -version

echo "Installing Zookeeper..."
ZK_VER=3.4.9
sudo rm -rf /tmp/zookeeper*
sudo curl -sf -o /tmp/zookeeper-${ZK_VER}.tar.gz -L https://www.apache.org/dist/zookeeper/zookeeper-${ZK_VER}/zookeeper-${ZK_VER}.tar.gz
sudo tar -xzf /tmp/zookeeper-${ZK_VER}.tar.gz -C /tmp/
sudo mv /tmp/zookeeper-${ZK_VER} /tmp/zookeeper
sudo chmod -R 777 /tmp/zookeeper/
mkdir -p /tmp/zookeeper/data.zk
touch /tmp/zookeeper/data.zk/myid
sudo chmod -R 777 /tmp/zookeeper/data.zk/

echo "Done!"
