#!/bin/bashexport

. scripts/utils.sh

ORG_NAME="orderer.mvg-sky.com"
ORG_DEFINITION_PATH="${PWD}/organizations/${ORG_NAME}"
ORG_DIST_PATH="${PWD}/dist/organizations/ordererOrganizations/${ORG_NAME}"
COMPOSE_CA="compose.ca.yaml"
COMPOSE_CLI="compose.cli.yaml"
COMPOSE_ORDERERS=(
  "compose.orderer0.yaml"
  "compose.orderer1.yaml"
  "compose.orderer2.yaml"
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

function cpConfigs() {
  mkdir -p "${ORG_DIST_PATH}/config"
  cp "${ORG_DEFINITION_PATH}/config/config.orderer.yaml" "${ORG_DIST_PATH}/config/orderer.yaml"
}

function create() {
  local COMPOSE_FILES="-f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CA}"

  for FILE in "${COMPOSE_ORDERERS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  set -x
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} ${COMPOSE_FILES} up -d 2>&1
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} ps -a
  { set +x; } 2>/dev/null

  if [ "${?}" -ne 0 ]; then
    fatalln "Unable to start network of ${ORG_NAME}"
  fi
}

function delete() {
  local COMPOSE_FILES="-f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CA}"

  for FILE in "${COMPOSE_ORDERERS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  set -x
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} ${COMPOSE_FILES} down --volumes --remove-orphans
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} network rm "network.${ORG_NAME}"
  { set +x; } 2>/dev/null
}

function startup() {
  local COMPOSE_FILES=""

  for FILE in "${COMPOSE_ORDERERS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  set -x
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} ${COMPOSE_FILES} up -d 2>&1
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} ps -a
  { set +x; } 2>/dev/null

  if [ "${?}" -ne 0 ]; then
    fatalln "Unable to start network of ${ORG_NAME}"
  fi
}

function shutdown() {
  local COMPOSE_FILES="-f ${ORG_DEFINITION_PATH}/compose/${COMPOSE_CA}"

  for FILE in "${COMPOSE_ORDERERS[@]}"; do
    COMPOSE_FILES="${COMPOSE_FILES} -f ${ORG_DEFINITION_PATH}/compose/${FILE}"
  done

  set -x
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} ${COMPOSE_FILES} down --remove-orphans
  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_CLI} network rm "network.${ORG_NAME}"
  { set +x; } 2>/dev/null
}

function configGlobals() {
  local ORDERER="${1}"

  export ORDERER_NAME="orderer${ORDERER}.${ORG_NAME}"
  export ORDERER_CA="${ORG_DIST_PATH}/tlsca/tlsca.${ORG_NAME}-cert.pem"
  export ORDERER_ADMIN_TLS_SIGN_CERT="${ORG_DIST_PATH}/orderers/orderer${ORDERER}.${ORG_NAME}/tls/server.crt"
  export ORDERER_ADMIN_TLS_PRIVATE_KEY="${ORG_DIST_PATH}/orderers/orderer${ORDERER}.${ORG_NAME}/tls/server.key"
}
