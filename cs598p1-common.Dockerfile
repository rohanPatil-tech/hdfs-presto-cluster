####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

FROM openjdk:11

RUN apt update && \
    apt upgrade --yes && \
    apt install ssh openssh-server --yes

# Setup common SSH key.
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/shared_rsa -C common && \
    cat ~/.ssh/shared_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

RUN apt-get install net-tools

RUN apt install python-is-python3

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################

# Setup HDFS/Presto resources here

# Define environment variables
ENV HADOOP_VERSION=3.3.6
ENV HIVE_VERSION=4.0.0
ENV PRESTO_VERSION=0.290
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_MAPRED_HOME=/opt/hadoop
ENV HIVE_HOME=/opt/hive
ENV PRESTO_HOME=/opt/presto
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PRESTO_HOME/bin:$PATH
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV CLASSPATH=$CLASSPATH:$HADOOP_HOME/lib/*:$HIVE_HOME/lib/*

# Download and Install Hadoop
WORKDIR /opt
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -xvzf hadoop-$HADOOP_VERSION.tar.gz && \
    mv hadoop-$HADOOP_VERSION hadoop && \
    rm hadoop-$HADOOP_VERSION.tar.gz

# Configure Hadoop
COPY core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
COPY yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
# Copy resources
COPY resources /opt/resources

# Setup Hadoop environment
RUN echo "export JAVA_HOME=/usr/local/openjdk-11" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_NAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export PATH=\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin:\$PATH" >> ~/.bashrc

# Format and start HDFS
RUN $HADOOP_HOME/bin/hdfs namenode -format

RUN wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz && \
    tar -xvzf apache-hive-$HIVE_VERSION-bin.tar.gz && \
    mv apache-hive-$HIVE_VERSION-bin hive && \
    rm apache-hive-$HIVE_VERSION-bin.tar.gz

# Configure Hive
COPY hive-site.xml $HIVE_HOME/conf/hive-site.xml
RUN mkdir -p $HIVE_HOME/metastore_db

# Download and Install Presto
RUN wget https://repo1.maven.org/maven2/com/facebook/presto/presto-server/$PRESTO_VERSION/presto-server-$PRESTO_VERSION.tar.gz && \
    tar -xvzf presto-server-$PRESTO_VERSION.tar.gz && \
    mv presto-server-$PRESTO_VERSION presto && \
    rm presto-server-$PRESTO_VERSION.tar.gz && \
    mkdir -p $PRESTO_HOME/etc/catalog

# Configure Presto
COPY jvm.config $PRESTO_HOME/etc/jvm.config
COPY hive.properties $PRESTO_HOME/etc/catalog/hive.properties

# RUN echo "node.environment=production" >> ${PRESTO_HOME}/etc/node.properties
# RUN echo "node.id=${NODE_ID}" >> ${PRESTO_HOME}/etc/node.properties
# RUN echo "node.data-dir=/var/presto/data" >> ${PRESTO_HOME}/etc/node.properties

RUN mkdir -p $PRESTO_HOME/plugin/hive-hadoop2 && \
    wget https://repo1.maven.org/maven2/com/facebook/presto/presto-hive/$PRESTO_VERSION/presto-hive-$PRESTO_VERSION.jar -O $PRESTO_HOME/plugin/hive-hadoop2/presto-hive-$PRESTO_VERSION.jar

# Download Presto CLI
RUN wget https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/$PRESTO_VERSION/presto-cli-$PRESTO_VERSION-executable.jar && \
    mv presto-cli-$PRESTO_VERSION-executable.jar /usr/local/bin/presto && \
    chmod +x /usr/local/bin/presto

# Download PostgreSQL
RUN apt install -y postgresql postgresql-contrib
RUN wget -P /opt/hive/lib https://jdbc.postgresql.org/download/postgresql-42.3.8.jar


RUN apt-get install -y less

# Start services
# CMD service ssh start && \
#     $HADOOP_HOME/sbin/start-dfs.sh && \
#     $HADOOP_HOME/sbin/start-yarn.sh && \
#     $HIVE_HOME/bin/schematool -initSchema -dbType derby && \
#     $PRESTO_HOME/bin/launcher start && \
#     bash
