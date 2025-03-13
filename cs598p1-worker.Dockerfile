####################################################################################
# DO NOT MODIFY THE BELOW ##########################################################

FROM cs598p1-common

# DO NOT MODIFY THE ABOVE ##########################################################
####################################################################################
COPY config.properties.worker $PRESTO_HOME/etc/config.properties
COPY ./setup-worker.sh ./setup-worker.sh
RUN /bin/bash setup-worker.sh

COPY ./start-worker.sh ./start-worker.sh
CMD ["/bin/bash", "start-worker.sh"]