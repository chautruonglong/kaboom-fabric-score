#!/bin/bash

. scripts/utils.sh

export PATH=${PWD}/bin:$PATH
export VERBOSE=false

CRYPTO="cryptogen"
MAX_RETRY=5
CLI_DELAY=3
CHANNEL_NAME="kaboom-channel"
CC_NAME="NA"
CC_SRC_PATH="NA"
CC_END_POLICY="NA"
CC_COLL_CONFIG="NA"
CC_INIT_FCN="NA"
CC_SRC_LANGUAGE="NA"
CCAAS_DOCKER_RUN=true
CC_VERSION="1.0"
CC_SEQUENCE=1
DATABASE="leveldb"
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"
NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

: ${DOCKER_CLI:="docker"}
: ${DOCKER_COMPOSE_CLI:="${DOCKER_CLI} compose"}
infoln "Using ${DOCKER_CLI} and ${DOCKER_COMPOSE_CLI}"

checkPrereqs

function createOrganizations() {
  if [ "$CRYPTO" == "cryptogen" ]; then
    source "${PWD}/scripts/kaboom-organization.sh" && generateCrypto
    source "${PWD}/scripts/orderer-organization.sh" && generateCrypto
  elif [ "$CRYPTO" == "Certificate Authorities" ]; then
    source "${PWD}/scripts/kaboom-organization.sh" && generateCA
    source "${PWD}/scripts/orderer-organization.sh" && generateCA
  fi

  source "${PWD}/scripts/kaboom-organization.sh" && generateCCP
  source "${PWD}/scripts/kaboom-organization.sh" && cpConfigs

  source "${PWD}/scripts/orderer-organization.sh" && cpConfigs
}

function networkUp() {
  if [ "${MODE}" == "startup" ]; then
    infoln "Startup network"
    source "${PWD}/scripts/kaboom-organization.sh" && startup
    source "${PWD}/scripts/orderer-organization.sh" && startup
  elif [ "${MODE}" == "create" ]; then
    infoln "Creating all organizations"
    createOrganizations

    infoln "Creating channel genesis block"
    source "${PWD}/scripts/channel.sh" && createChannelGenesisBlock

    infoln "Creating network"
    source "${PWD}/scripts/kaboom-organization.sh" && create
    source "${PWD}/scripts/orderer-organization.sh" && create
  fi
}

function networkDown() {
  if [ "${MODE}" == "shutdown" ]; then
    infoln "Shutdown network"
    source "${PWD}/scripts/kaboom-organization.sh" && shutdown
    source "${PWD}/scripts/orderer-organization.sh" && shutdown
  elif [ "${MODE}" == "delete" ]; then
    infoln "Delete network"
    source "${PWD}/scripts/kaboom-organization.sh" && delete
    source "${PWD}/scripts/orderer-organization.sh" && delete
    ${DOCKER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf ${PWD}/dist'
  fi
}

function createNetworkChannel() {
  source "${PWD}/scripts/orderer-organization.sh" && configGlobals 0
  source "${PWD}/scripts/kaboom-organization.sh" && configGlobals 0

  source "${PWD}/scripts/channel.sh" && createChannel $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE

  source "${PWD}/scripts/kaboom-organization.sh" && peerJoinChannel $CHANNEL_NAME
  source "${PWD}/scripts/kaboom-organization.sh" && setAnchorPeers $CHANNEL_NAME
}

function deployCC() {
  source "${PWD}/scripts/kaboom-organization.sh" && applyChaincode $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE

  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode failed"
  fi
}

function deployCCAAS() {
  source "${PWD}/scripts/kaboom-organization.sh" && applyChaincodeAAS $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CCAAS_DOCKER_RUN $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE $CCAAS_DOCKER_RUN

  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode-as-a-service failed"
  fi
}

function explorerUp() {
  export EXPLORER_CONFIG_FILE_PATH="${PWD}/explorer/config.json"
  export EXPLORER_PROFILE_DIR_PATH="${PWD}/explorer/connection-profile"
  export FABRIC_CRYPTO_PATH="${PWD}/dist/organizations"

  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} -f "${PWD}/explorer/compose.explorer.yaml" up -d
}

function explorerDown() {
  export EXPLORER_CONFIG_FILE_PATH="${PWD}/explorer/config.json"
  export EXPLORER_PROFILE_DIR_PATH="${PWD}/explorer/connection-profile"
  export FABRIC_CRYPTO_PATH="${PWD}/dist/organizations"

  DOCKER_SOCK="${DOCKER_SOCK}" ${DOCKER_COMPOSE_CLI} -f "${PWD}/explorer/compose.explorer.yaml" down
}

if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp $MODE
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -ccl )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION="$2"
    shift
    ;;
  -ccs )
    CC_SEQUENCE="$2"
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY="$2"
    shift
    ;;
  -cccg )
    CC_COLL_CONFIG="$2"
    shift
    ;;
  -cci )
    CC_INIT_FCN="$2"
    shift
    ;;
  -ccaasdocker )
    CCAAS_DOCKER_RUN="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

if [ "$MODE" == "create" ]; then
  networkUp
elif [ "$MODE" == "delete" ]; then
  networkDown
elif [ "$MODE" == "startup" ]; then
  networkUp
elif [ "$MODE" == "shutdown" ]; then
  networkDown
elif [ "$MODE" == "createChannel" ]; then
  createNetworkChannel
elif [ "$MODE" == "deployCC" ]; then
  deployCC
elif [ "$MODE" == "deployCCAAS" ]; then
  deployCCAAS
elif [ "$MODE" == "explorerUp" ]; then
  explorerUp
elif [ "$MODE" == "explorerDown" ]; then
  explorerDown
else
  printHelp
  exit 1
fi
