#!/bin/bash

. scripts/utils.sh
. scripts/configUpdate.sh

createAnchorPeerUpdate() {
  local CHANNEL_NAME="${1}"

  infoln "Fetching channel config for channel ${CHANNEL_NAME}"
  fetchChannelConfig ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json 0

  infoln "Generating anchor ${PEER_NAME} update transaction for Org${ORG} on channel ${CHANNEL_NAME}"

  set -x
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'${HOST}'","port": '${PORT}'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
  RES="${?}"
  { set +x; } 2>/dev/null

  createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  local CHANNEL_NAME="${1}"

  set -x
  peer channel update -o orderer0.orderer.mvg-sky.com:7050 --ordererTLSHostnameOverride orderer0.orderer.mvg-sky.com -c ${CHANNEL_NAME} -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "${ORDERER_CA}"
  RES="${?}"
  { set +x; } 2>/dev/null

  verifyResult ${RES} "Anchor peer update failed"
  successln "Anchor ${PEER_NAME} set for org '${CORE_PEER_LOCALMSPID}' on channel '${CHANNEL_NAME}'"
}
