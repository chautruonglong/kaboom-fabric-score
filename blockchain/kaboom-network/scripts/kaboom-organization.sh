#!/bin/bashexport

. scripts/utils.sh

ORG_NAME="kaboom.mvg-sky.com"
ORG_DEFINITION_PATH="${PWD}/organizations/${ORG_NAME}"
ORG_DIST_PATH="${PWD}/dist/organizations/peerOrganizations/${ORG_NAME}"
COMPOSE_CA="compose.ca.yaml"
COMPOSE_CLI="compose.cli.yaml"
COMPOSE_PEERS=(
  "compose.peer0.yaml"
  "compose.peer1.yaml"
  "compose.peer2.yaml"
)
COMPOSE_COUCHDBS=(
  "compose.couchdb0.yaml"
  "compose.couchdb1.yaml"
  "compose.couchdb2.yaml"
)

function generateCrypto() {
  if [ -d "${ORG_DIST_PATH}" ]; then
    rm -rf "${ORG_DIST_PATH}"
  fi

  infoln "Genrating certificates for ${ORG_NAME} using cryptogen"

  set -x
  cryptogen generate --config="${ORG_DEFINITION_PATH}/config/config.crypto.yaml" --output="${PWD}/dist/organizations"
  RES="${?}"
  { set +x; } 2>/dev/null

  if [ "${RES}" -ne 0 ]; then
    fatalln "Failed to generate certificates for ${ORG_NAME}"
  fi
}

function generateCA() {
  if [ -d "${ORG_DIST_PATH}" ]; then
    rm -rf "${ORG_DIST_PATH}"
  fi

  mkdir -p "${ORG_DIST_PATH}/fabric-ca"
  cp "${ORG_DEFINITION_PATH}/config/config.ca.yaml" "${ORG_DIST_PATH}/fabric-ca/fabric-ca-server-config.yaml"

  infoln "Generating certificates for ${ORG_NAME} using Fabric CA"

  source "${ORG_DEFINITION_PATH}/enrollment.sh"

  ${DOCKER_COMPOSE_CLI} -f "${ORG_DEFINITION_PATH}/compose/${COMPOSE_CA}" up -d 2>&1

  infoln "Creating ${ORG_NAME} identities"

  while :; do
    if [ ! -f "${ORG_DIST_PATH}/fabric-ca/tls-cert.pem" ]; then
      sleep 1
    else
      enroll
      break
    fi
  done
}

function generateCCP() {
  source "${ORG_DEFINITION_PATH}/ccp-generate.sh"
}

function cpConfigs() {
  mkdir -p "${ORG_DIST_PATH}/config"
  cp "${ORG_DEFINITION_PATH}/config/config.core.yaml" "${ORG_DIST_PATH}/config/core.yaml"
}

function create() {
  local COMPOSE_FILES="-f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CLI}"

  for FILE in "${COMPOSE_PEERS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  if [ "${DATABASE}" == "couchdb" ]; then
    for FILE in "${COMPOSE_COUCHDBS[@]}"; do
      COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
    done
  fi

  set -x
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} ${COMPOSE_FILES} up -d 2>&1
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} ps -a
  { set +x; } 2>/dev/null

  if [ "${?}" -ne 0 ]; then
    fatalln "Unable to start network of ${ORG_NAME}"
  fi
}

function delete() {
  local COMPOSE_FILES="-f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CLI}"

  COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CA}"

  for FILE in "${COMPOSE_PEERS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  for FILE in "${COMPOSE_COUCHDBS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  set -x
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} ${COMPOSE_FILES} down --volumes --remove-orphans
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} rm -f $(${DOCKER_CLI} ps -aq --filter label=service=fabric.kaboom.mvg-sky.com)
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} network rm "network.${ORG_NAME}"
  { set +x; } 2>/dev/null
}

function startup() {
  local COMPOSE_FILES="-f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CLI}"

  COMPOSE_FILES="-f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CA}"

  for FILE in "${COMPOSE_PEERS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  if [ "${DATABASE}" == "couchdb" ]; then
    for FILE in "${COMPOSE_COUCHDBS[@]}"; do
      COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
    done
  fi

  set -x
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} ${COMPOSE_FILES} up -d 2>&1
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} ps -a
  { set +x; } 2>/dev/null

  if [ "${?}" -ne 0 ]; then
    fatalln "Unable to start network of ${ORG_NAME}"
  fi
}

function shutdown() {
  local COMPOSE_FILES="-f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CLI}"

  COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CA}"

  for FILE in "${COMPOSE_PEERS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  for FILE in "${COMPOSE_COUCHDBS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  set -x
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} ${COMPOSE_FILES} down --remove-orphans
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} rm -f $(${DOCKER_CLI} ps -aq --filter label=service=fabric.kaboom.mvg-sky.com)
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} network rm "network.${ORG_NAME}"
  { set +x; } 2>/dev/null
}

function configGlobals() {
  local PEER="${1}"

  export CORE_PEER_TLS_ENABLED="true"
  export CORE_PEER_LOCALMSPID="KaboomMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="${ORG_DIST_PATH}/tlsca/tlsca.${ORG_NAME}-cert.pem"
  export CORE_PEER_MSPCONFIGPATH="${ORG_DIST_PATH}/users/Admin@${ORG_NAME}/msp"
  export PEER_NAME="peer${PEER}.${ORG_NAME}"
  export HOST="peer${PEER}.${ORG_NAME}"

  infoln "Using peer${PEER} of ${ORG_NAME} organization"

  if [ "${PEER}" -eq 0 ]; then
    export CORE_PEER_ADDRESS="localhost:7051"
    export PORT=7051
  elif [ "${PEER}" -eq 1 ]; then
    export CORE_PEER_ADDRESS="localhost:8051"
    export PORT=8051
  elif [ "${PEER}" -eq 2 ]; then
    export CORE_PEER_ADDRESS="localhost:9051"
    export PORT=9051
  else
    errorln "The ${ORG_NAME} organization do not have peer${PEER}"
  fi
}

function configGlobalsCLI() {
  local PEER="${1}"

  export CORE_PEER_LOCALMSPID="KaboomMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="${ORG_DIST_PATH}/tlsca/tlsca.${ORG_NAME}-cert.pem"
  export CORE_PEER_MSPCONFIGPATH="${ORG_DIST_PATH}/users/Admin@${ORG_NAME}/msp"
  export PEER_NAME="peer${PEER}.${ORG_NAME}"
  export HOST="peer${PEER}.${ORG_NAME}"

  infoln "Using CLI peer${PEER} of ${ORG_NAME} organization"

  if [ "${PEER}" -eq 0 ]; then
    export CORE_PEER_ADDRESS="peer0.${ORG_NAME}:7051"
    export PORT=7051
  elif [ "${PEER}" -eq 1 ]; then
    export CORE_PEER_ADDRESS="peer0.${ORG_NAME}:8051"
    export PORT=8051
  elif [ "${PEER}" -eq 2 ]; then
    export CORE_PEER_ADDRESS="peer0.${ORG_NAME}:9051"
    export PORT=9051
  else
    errorln "The ${ORG_NAME} organization do not have peer${PEER}"
  fi
}

function peerJoinChannel() {
  export CHANNEL_NAME="${1}"
  export FABRIC_CFG_PATH="${ORG_DIST_PATH}/config"
  export BLOCKFILE="${PWD}/dist/channel-artifacts/${CHANNEL_NAME}.block"

  configGlobals 0
  source "${PWD}/scripts/channel.sh" && joinChannel

  configGlobals 1
  source "${PWD}/scripts/channel.sh" && joinChannel

  configGlobals 2
  source "${PWD}/scripts/channel.sh" && joinChannel
}

function setAnchorPeers() {
  export CHANNEL_NAME="${1}"

  ${DOCKER_CLI} exec "cli.${ORG_NAME}" /bin/bash -c "
    source scripts/orderer-organization.sh && configGlobals 0
    source scripts/kaboom-organization.sh
    source scripts/anchorPeer.sh

    configGlobalsCLI 0
    createAnchorPeerUpdate ${CHANNEL_NAME}
    updateAnchorPeer ${CHANNEL_NAME}

    configGlobalsCLI 1
    createAnchorPeerUpdate ${CHANNEL_NAME}
    updateAnchorPeer ${CHANNEL_NAME}

    configGlobalsCLI 2
    createAnchorPeerUpdate ${CHANNEL_NAME}
    updateAnchorPeer ${CHANNEL_NAME}
  "
}

function applyChaincode() {
  export FABRIC_CFG_PATH="${ORG_DIST_PATH}/config"
  export -f configGlobals
  export -f configGlobalsCLI

  source "${PWD}/scripts/orderer-organization.sh" && configGlobals 0
  source "${PWD}/scripts/kaboom-organization.sh"
  source "${PWD}/scripts/deployCC.sh" $@
}

function applyChaincodeAAS() {
  export FABRIC_CFG_PATH="${ORG_DIST_PATH}/config"
  export CCAAS_CONTAINER_NAME=chaincode.${ORG_NAME}
  export CCAAS_SERVER_PORT=9999

  export -f configGlobals
  export -f configGlobalsCLI

  source "${PWD}/scripts/orderer-organization.sh" && configGlobals 0
  source "${PWD}/scripts/kaboom-organization.sh"
  source "${PWD}/scripts/deployCCAAS.sh" $@
}
