#!/bin/bash

####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

# Exchange SSH keys.
/etc/init.d/ssh start
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/shared_rsa
ssh-copy-id -i ~/.ssh/id_rsa -o 'IdentityFile ~/.ssh/shared_rsa' -o StrictHostKeyChecking=no -f worker1
ssh-copy-id -i ~/.ssh/id_rsa -o 'IdentityFile ~/.ssh/shared_rsa' -o StrictHostKeyChecking=no -f worker2
start-dfs.sh
start-yarn.sh
# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

service postgresql start
su - postgres -c "psql -c \"CREATE DATABASE metastore;\""
su - postgres -c "psql -c \"CREATE USER hiveuser WITH PASSWORD 'hivepassword';\""
su - postgres -c "psql -c \"ALTER ROLE hiveuser SET client_encoding TO 'utf8';\""
su - postgres -c "psql -c \"ALTER ROLE hiveuser SET default_transaction_isolation TO 'read committed';\""
su - postgres -c "psql -c \"ALTER ROLE hiveuser SET timezone TO 'UTC';\""
su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE metastore TO hiveuser;\""

schematool -dbType postgres -initSchema
hive --service metastore &

# Start HDFS/Hive Metastore/Presto main here
/opt/presto/bin/launcher start

bash