#!/bin/bash

####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

/etc/init.d/ssh start
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/shared_rsa
start-dfs.sh
# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# # Setup HDFS/Presto worker here
# Ensure NODE_ID is set; otherwise, generate a random UUID
echo ${NODE_ID}
# Write node.properties with the dynamically assigned node ID
cat <<EOF > ${PRESTO_HOME}/etc/node.properties
node.environment=production
node.id=${NODE_ID}
node.data-dir=/var/presto/data
EOF

# Start HDFS/Presto worker here
sleep 15
/opt/presto/bin/launcher start

bash

