#!/bin/bash

# Install images and tools
source ${PWD}/install-fabric.sh d b
rm -rf ${PWD}/config

# Startup network
source ${PWD}/network.sh create -ca -s couchdb

# Join channel
source ${PWD}/network.sh createChannel

# Deploy chaincode as a service
source ${PWD}/network.sh deployCCAAS -ccn basic -ccp ../test-chaincode-java -ccl java

# Startup explorer
source ${PWD}/network.sh explorerUp

docker ps -a
