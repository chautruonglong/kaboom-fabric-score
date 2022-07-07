#!/bin/bash

function installChaincode() {
  configGlobals $1

  mkdir -p dist/chaincode/

  set -x
  peer lifecycle chaincode install dist/chaincode/${CC_NAME}.tar.gz
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "Chaincode installation on ${PEER_NAME} has failed"
  successln "Chaincode is installed on ${PEER_NAME}"
}

function queryInstalled() {
  configGlobals $1

  set -x
  OUTPUT=$(peer lifecycle chaincode queryinstalled)
  res=$?
  { set +x; } 2>/dev/null

  PACKAGE_ID=$(echo $OUTPUT | sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Installed chaincodes on peer: Package ID: //; s/, Label:.*$//; p;}")
  verifyResult $res "Query installed on ${PEER_NAME} has failed"
  successln "Query installed successful on ${PEER_NAME} on channel"
}

function approveForMyOrg() {
  configGlobals $1

  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer0.orderer.mvg-sky.com --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG}
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "Chaincode definition approved on ${PEER_NAME} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on ${PEER_NAME} on channel '$CHANNEL_NAME'"
}

function checkCommitReadiness() {
  configGlobals $1

  infoln "Checking the commit readiness of the chaincode definition on ${PEER_NAME} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to check the commit readiness of the chaincode definition on ${PEER_NAME}, Retry after $DELAY seconds."

    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json
    res=$?
    { set +x; } 2>/dev/null

    let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done

  if test $rc -eq 0; then
    infoln "Checking the commit readiness of the chaincode definition successful on ${PEER_NAME} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Check commit readiness result on ${PEER_NAME} is INVALID!"
  fi
}

function commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer0.orderer.mvg-sky.com --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} "${PEER_CONN_PARMS[@]}" --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG}
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "Chaincode definition commit failed on ${PEER_NAME} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

function queryCommitted() {
  configGlobals 1

  infoln "Querying chaincode definition on ${PEER_NAME} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  local EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query committed status on ${PEER_NAME}, Retry after $DELAY seconds."

    set -x
    OUTPUT=$(peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME})
    res=$?
    { set +x; } 2>/dev/null

    test $res -eq 0 && VALUE=$(echo $OUTPUT | grep -o 'Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done

  if test $rc -eq 0; then
    successln "Query chaincode definition successful on ${PEER_NAME} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query chaincode definition result on ${PEER_NAME} is INVALID!"
  fi
}

function chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  set -x
  fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'
  infoln "invoke fcn call:${fcn_call}"
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer0.orderer.mvg-sky.com --tls --cafile "$ORDERER_CA" -C $CHANNEL_NAME -n ${CC_NAME} "${PEER_CONN_PARMS[@]}" --isInit -c ${fcn_call}
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "Invoke execution on $PEERS failed "
  successln "Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME'"
}

function chaincodeQuery() {
  configGlobals $1

  infoln "Querying on ${PEER_NAME} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query ${PEER_NAME}, Retry after $DELAY seconds."
    set -x
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["org.hyperledger.fabric:GetMetadata"]}'
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  if test $rc -eq 0; then
    successln "Query successful on ${PEER_NAME} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query result on ${PEER_NAME} is INVALID!"
  fi
}

function parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""

  while [ "$#" -gt 0 ]; do
    configGlobals $1
    PEER="${PEER_NAME}"

    if [ -z "$PEERS" ]; then
	    PEERS="$PEER"
    else
	    PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    TLSINFO=(--tlsRootCertFiles "${CORE_PEER_TLS_ROOTCERT_FILE}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    shift
  done
}
