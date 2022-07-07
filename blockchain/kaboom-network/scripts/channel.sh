#!/bin/bash

. scripts/utils.sh

: ${CHANNEL_NAME:="kaboom-channel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

: ${DOCKER_CLI:="docker"}
: ${DOCKER_COMPOSE_CLI:="${DOCKER_CLI} compose"}

infoln "Using ${DOCKER_CLI} and ${DOCKER_COMPOSE_CLI}"

createChannelGenesisBlock() {
  if [ ! -d "${PWD}/dist/channel-artifacts" ]; then
    mkdir -p "${PWD}/dist/channel-artifacts"
  fi

  export FABRIC_CFG_PATH="${PWD}/channels"

  set -x
  configtxgen -profile "OrgApplicationGenesis" -outputBlock "${PWD}/dist/channel-artifacts/${CHANNEL_NAME}.block" -channelID "${CHANNEL_NAME}"
  res=$?
  { set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
  local CHANNEL_NAME="${1}"
  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY

    set -x
    osnadmin channel join --channelID ${CHANNEL_NAME} --config-block ./dist/channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
    res=$?
    { set +x; } 2>/dev/null

    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  verifyResult $res "Channel creation failed"
}

joinChannel() {
  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY

    set -x
    peer channel join -b $BLOCKFILE
    res=$?
    { set +x; } 2>/dev/null

    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  verifyResult $res "After $MAX_RETRY attempts, ${PEER_NAME} has failed to join channel '${CHANNEL_NAME}' "
}

# setAnchorPeer() {
#   ORG=$1
#   PEER=$2
#   ${DOCKER_CLI} exec cli ./scripts/setAnchorPeer.sh $ORG $PEER ${CHANNEL_NAME}
# }

# FABRIC_CFG_PATH=${PWD}/config

# # infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
# # createChannelGenesisBlock

# FABRIC_CFG_PATH=${PWD}/config
# BLOCKFILE="./dist/channel-artifacts/${CHANNEL_NAME}.block"

# # infoln "Creating channel ${CHANNEL_NAME}"
# # createChannel
# # successln "Channel '${CHANNEL_NAME}' created"

# infoln "Joining org1 peer to the channel..."
# joinChannel 1 0
# setAnchorPeer 1 0

# infoln "Setting anchor peer for org1..."
# joinChannel 1 1
# setAnchorPeer 1 1

# successln "Channel '${CHANNEL_NAME}' joined"
