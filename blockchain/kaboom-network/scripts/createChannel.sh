#!/bin/bash

. scripts/envVar.sh
. scripts/utils.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

if [ ! -d "./dist/channel-artifacts" ]; then
	mkdir ./dist/channel-artifacts
fi

createChannelGenesisBlock() {
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	set -x
	configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ${PWD}/.dist/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
  	verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	mkdir -p ${PWD}/.dist/logs

	setGlobals 1

	local rc=1
	local COUNTER=1

	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
		sleep $DELAY

		set -x
		osnadmin channel join --channelID $CHANNEL_NAME --config-block ${PWD}/.dist/channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&${PWD}/.dist/logs/log.txt
		res=$?
		{ set +x; } 2>/dev/null

		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done

	cat ${PWD}/.dist/logs/log.txt
	verifyResult $res "Channel creation failed"
}

joinChannel() {
	mkdir -p ${PWD}/.dist/logs

	FABRIC_CFG_PATH=$PWD/config/
	ORG=$1
	setGlobals $ORG

	local rc=1
	local COUNTER=1

	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY

    set -x
    peer channel join -b $BLOCKFILE >&${PWD}/.dist/logs/log.txt
    res=$?
    { set +x; } 2>/dev/null

    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
	done

	cat ${PWD}/.dist/logs/log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ORG=$1
  if [ $ORG -eq 1 ]; then
  	${CONTAINER_CLI} exec cli.org1 ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME 
  elif [ $ORG -eq 2 ]; then
  	${CONTAINER_CLI} exec cli.org2 ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME 
  fi
}

FABRIC_CFG_PATH=${PWD}/configtx

infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
createChannelGenesisBlock

FABRIC_CFG_PATH=$PWD/config/
BLOCKFILE="${PWD}/.dist/channel-artifacts/${CHANNEL_NAME}.block"

infoln "Creating channel ${CHANNEL_NAME}"
createChannel
successln "Channel '$CHANNEL_NAME' created"

infoln "Joining org1 peer to the channel..."
joinChannel 1
infoln "Joining org2 peer to the channel..."
joinChannel 2

infoln "Setting anchor peer for org1..."
setAnchorPeer 1
infoln "Setting anchor peer for org2..."
setAnchorPeer 2

successln "Channel '$CHANNEL_NAME' joined"
