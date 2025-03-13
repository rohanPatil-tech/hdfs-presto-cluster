#!/bin/bash
# export JAVA_HOME=/usr/local/openjdk-8/jre

####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Setup HDFS/Presto main here

# Ensure NODE_ID is set; otherwise, generate a random UUID
if [ -z "$NODE_ID" ]; then
    NODE_ID=$(cat /proc/sys/kernel/random/uuid)
fi

# Write node.properties with the dynamically assigned node ID
cat <<EOF > ${PRESTO_HOME}/etc/node.properties
node.environment=production
node.id=main
node.data-dir=/var/presto/data
EOF