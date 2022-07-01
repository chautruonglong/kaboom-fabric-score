#!/bin/bash

ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH=${ROOTDIR}/bin:${PWD}/bin:$PATH
export VERBOSE=false

pushd ${ROOTDIR} > /dev/null
trap "popd > /dev/null" EXIT

. scripts/utils.sh

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

function clearContainers() {
  infoln "Removing remaining containers"
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter name='dev-peer*') 2>/dev/null || true
}

function removeUnwantedImages() {
  infoln "Removing generated chaincode docker images"
  ${CONTAINER_CLI} image rm -f $(${CONTAINER_CLI} images -aq --filter reference='dev-peer*') 2>/dev/null || true
}

NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

function createOrgs() {
  if [ -d ".dist/organizations/peer-organizations" ]; then
    rm -Rf .dist/organizations/peer-organizations && rm -Rf .dist/organizations/orderer-organizations
  fi

  if [ "$CRYPTO" == "cryptogen" ]; then
    which cryptogen
    if [ "$?" -ne 0 ]; then
      fatalln "cryptogen tool not found. exiting"
    fi
    infoln "Generating certificates using cryptogen tool"

    infoln "Creating Org1 Identities"

    set -x
    cryptogen generate --config=./organizations/org1/config/crypto-config.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Org2 Identities"

    set -x
    cryptogen generate --config=./organizations/org2/config/crypto-config.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Orderer Org Identities"

    set -x
    cryptogen generate --config=./organizations/orderer/config/crypto-config.yaml --output="organizations"
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

  fi

  if [ "$CRYPTO" == "Certificate Authorities" ]; then
    infoln "Generating certificates using Fabric CA"

    mkdir -p ./.dist/organizations/orderer-organizations/example.com/fabric-ca
    cp ./organizations/orderer/config/ca-config.yaml ./.dist/organizations/orderer-organizations/example.com/fabric-ca/fabric-ca-server-config.yaml

    mkdir -p ./.dist/organizations/peer-organizations/org1.example.com/fabric-ca
    cp ./organizations/org1/config/ca-config.yaml ./.dist/organizations/peer-organizations/org1.example.com/fabric-ca/fabric-ca-server-config.yaml

    mkdir -p ./.dist/organizations/peer-organizations/org2.example.com/fabric-ca
    cp ./organizations/org2/config/ca-config.yaml ./.dist/organizations/peer-organizations/org2.example.com/fabric-ca/fabric-ca-server-config.yaml

    COMPOSE_FILE_CA="-f ./organizations/orderer/compose/compose-ca.yaml"
    COMPOSE_FILE_CA="${COMPOSE_FILE_CA} -f ./organizations/org1/compose/compose-ca.yaml"
    COMPOSE_FILE_CA="${COMPOSE_FILE_CA} -f ./organizations/org2/compose/compose-ca.yaml"

    DOCKER_SOCK="${DOCKER_SOCK}" ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILE_CA} up -d 2>&1

    while :; do
      if [ ! -f ".dist/organizations/peer-organizations/org1.example.com/fabric-ca/tls-cert.pem" ]; then
        sleep 1
      else
        break
      fi
    done

    infoln "Creating Org1 Identities"
    . ./organizations/org1/enrollment/register.sh
    registerForOrg1

    while :; do
      if [ ! -f ".dist/organizations/peer-organizations/org2.example.com/fabric-ca/tls-cert.pem" ]; then
        sleep 1
      else
        break
      fi
    done

    infoln "Creating Org2 Identities"
    . ./organizations/org2/enrollment/register.sh
    registerForOrg2

    while :; do
      if [ ! -f ".dist/organizations/orderer-organizations/example.com/fabric-ca/tls-cert.pem" ]; then
        sleep 1
      else
        break
      fi
    done

    infoln "Creating Orderer Org Identities"
    . ./organizations/orderer/enrollment/register.sh
    registerForOrdererOrg
  fi

  infoln "Generating CCP files for Org1 and Org2"
  ./organizations/org1/connection/ccp-generate.sh
  ./organizations/org2/connection/ccp-generate.sh
}

function networkUp() {
  checkPrereqs

  if [ ! -d ".dist/organizations/peer-organizations" ]; then
    createOrgs
  fi

  # orderer
  COMPOSE_FILES="-f ./organizations/orderer/compose/compose-orderer.yaml"

  # org1
  COMPOSE_FILES="${COMPOSE_FILES} -f ./organizations/org1/compose/compose-peer.yaml"
  COMPOSE_FILES="${COMPOSE_FILES} -f ./organizations/org1/compose/compose-cli.yaml"

  #org2
  COMPOSE_FILES="${COMPOSE_FILES} -f ./organizations/org2/compose/compose-peer.yaml"
  COMPOSE_FILES="${COMPOSE_FILES} -f ./organizations/org2/compose/compose-cli.yaml"

  if [ "${DATABASE}" == "couchdb" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f ./organizations/org1/compose/compose-couchdb.yaml"
    COMPOSE_FILES="${COMPOSE_FILES} -f ./organizations/org2/compose/compose-couchdb.yaml"
  fi

  DOCKER_SOCK="${DOCKER_SOCK}" ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} up -d 2>&1

  $CONTAINER_CLI ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

function createChannel() {
  bringUpNetwork="false"

  if ! $CONTAINER_CLI info > /dev/null 2>&1 ; then
    fatalln "$CONTAINER_CLI network is required to be running to create a channel"
  fi

  CONTAINERS=($($CONTAINER_CLI ps | grep hyperledger/ | awk '{print $2}'))
  len=$(echo ${#CONTAINERS[@]})

  if [[ $len -ge 4 ]] && [[ ! -d ".dist/organizations/peer-organizations" ]]; then
    echo "Bringing network down to sync certs with containers"
    networkDown
  fi

  [[ $len -lt 4 ]] || [[ ! -d ".dist/organizations/peer-organizations" ]] && bringUpNetwork="true" || echo "Network Running Already"

  if [ $bringUpNetwork == "true"  ]; then
    infoln "Bringing up network"
    networkUp
  fi

  scripts/createChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE
}

function deployCC() {
  scripts/deployCC.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE

  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode failed"
  fi
}

function deployCCAAS() {
  scripts/deployCCAAS.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CCAAS_DOCKER_RUN $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE $CCAAS_DOCKER_RUN

  if [ $? -ne 0 ]; then
    fatalln "Deploying chaincode-as-a-service failed"
  fi
}

function networkDown() {
  # orderer
  COMPOSE_BASE_FILES="-f ./organizations/orderer/compose/compose-orderer.yaml"

  # org1
  COMPOSE_BASE_FILES="${COMPOSE_BASE_FILES} -f ./organizations/org1/compose/compose-peer.yaml"
  COMPOSE_BASE_FILES="${COMPOSE_BASE_FILES} -f ./organizations/org1/compose/compose-cli.yaml"

  #org2
  COMPOSE_BASE_FILES="${COMPOSE_BASE_FILES} -f ./organizations/org2/compose/compose-peer.yaml"
  COMPOSE_BASE_FILES="${COMPOSE_BASE_FILES} -f ./organizations/org2/compose/compose-cli.yaml"

  COMPOSE_COUCH_FILES="-f ./organizations/org1/compose/compose-couchdb.yaml"
  COMPOSE_COUCH_FILES="${COMPOSE_COUCH_FILES} -f ./organizations/org2/compose/compose-couchdb.yaml"

  COMPOSE_CA_FILES="-f ./organizations/orderer/compose/compose-ca.yaml"
  COMPOSE_CA_FILES="${COMPOSE_CA_FILES} -f ./organizations/org1/compose/compose-ca.yaml"
  COMPOSE_CA_FILES="${COMPOSE_CA_FILES} -f ./organizations/org2/compose/compose-ca.yaml"

  COMPOSE_FILES="${COMPOSE_BASE_FILES} ${COMPOSE_COUCH_FILES} ${COMPOSE_CA_FILES}"

  COMPOSE_ORG3_BASE_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_BASE} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_BASE}"
  COMPOSE_ORG3_COUCH_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_COUCH} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_COUCH}"
  COMPOSE_ORG3_CA_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_CA} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_CA}"
  COMPOSE_ORG3_FILES="${COMPOSE_ORG3_BASE_FILES} ${COMPOSE_ORG3_COUCH_FILES} ${COMPOSE_ORG3_CA_FILES}"

  if [ "${CONTAINER_CLI}" == "docker" ]; then
    DOCKER_SOCK=$DOCKER_SOCK ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} ${COMPOSE_ORG3_FILES} down --volumes --remove-orphans
  elif [ "${CONTAINER_CLI}" == "podman" ]; then
    ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} ${COMPOSE_ORG3_FILES} down --volumes
  else
    fatalln "Container CLI  ${CONTAINER_CLI} not supported"
  fi

  if [ "$MODE" != "restart" ]; then
    ${CONTAINER_CLI} volume rm docker_orderer.example.com docker_peer0.org1.example.com docker_peer0.org2.example.com

    clearContainers
    removeUnwantedImages

    ${CONTAINER_CLI} kill $(${CONTAINER_CLI} ps -q --filter name=ccaas) || true

    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block .dist/organizations/peer-organizations .dist/organizations/orderer-organizations'
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf .dist/organizations/peer-organizations/org1.example.com/fabric-ca/msp .dist/organizations/peer-organizations/org1.example.com/fabric-ca/tls-cert.pem .dist/organizations/peer-organizations/org1.example.com/fabric-ca/ca-cert.pem .dist/organizations/peer-organizations/org1.example.com/fabric-ca/IssuerPublicKey .dist/organizations/peer-organizations/org1.example.com/fabric-ca/IssuerRevocationPublicKey .dist/organizations/peer-organizations/org1.example.com/fabric-ca/fabric-ca-server.db'
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf .dist/organizations/peer-organizations/org2.example.com/fabric-ca/msp .dist/organizations/peer-organizations/org2.example.com/fabric-ca/tls-cert.pem .dist/organizations/peer-organizations/org2.example.com/fabric-ca/ca-cert.pem .dist/organizations/peer-organizations/org2.example.com/fabric-ca/IssuerPublicKey .dist/organizations/peer-organizations/org2.example.com/fabric-ca/IssuerRevocationPublicKey .dist/organizations/peer-organizations/org2.example.com/fabric-ca/fabric-ca-server.db'
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf .dist/organizations/orderer-organizations/example.com/fabric-ca/msp .dist/organizations/orderer-organizations/example.com/fabric-ca/tls-cert.pem .dist/organizations/orderer-organizations/example.com/fabric-ca/ca-cert.pem .dist/organizations/orderer-organizations/example.com/fabric-ca/IssuerPublicKey .dist/organizations/orderer-organizations/example.com/fabric-ca/IssuerRevocationPublicKey .dist/organizations/orderer-organizations/example.com/fabric-ca/fabric-ca-server.db'
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf addOrg3/fabric-ca/org3/msp addOrg3/fabric-ca/org3/tls-cert.pem addOrg3/fabric-ca/org3/ca-cert.pem addOrg3/fabric-ca/org3/IssuerPublicKey addOrg3/fabric-ca/org3/IssuerRevocationPublicKey addOrg3/fabric-ca/org3/fabric-ca-server.db'
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf ./dist/channel-artifacts ${PWD}/.dist/logs/log.txt ./dist/chaincode*.tar.gz'

    rm -rf ${PWD}/.dist
  fi
}

# Using crpto vs CA. default is cryptogen
CRYPTO="cryptogen"
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
MAX_RETRY=5
# default for delay between commands
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# chaincode name defaults to "NA"
CC_NAME="NA"
# chaincode path defaults to "NA"
CC_SRC_PATH="NA"
# endorsement policy defaults to "NA". This would allow chaincodes to use the majority default policy.
CC_END_POLICY="NA"
# collection configuration defaults to "NA"
CC_COLL_CONFIG="NA"
# chaincode init function defaults to "NA"
CC_INIT_FCN="NA"
# use this as the default docker-compose yaml definition for org3
COMPOSE_FILE_ORG3_BASE=compose-org3.yaml
# use this as the docker compose couch file for org3
COMPOSE_FILE_ORG3_COUCH=compose-couch-org3.yaml
# certificate authorities compose file
COMPOSE_FILE_ORG3_CA=compose-ca-org3.yaml
#
# chaincode language defaults to "NA"
CC_SRC_LANGUAGE="NA"
# default to running the docker commands for the CCAAS
CCAAS_DOCKER_RUN=true
# Chaincode version
CC_VERSION="1.0"
# Chaincode definition sequence
CC_SEQUENCE=1
# default database
DATABASE="leveldb"

# Get docker sock path from environment variable
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]]; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

if [[ $# -ge 1 ]]; then
  key="$1"
  if [[ "$key" == "createChannel" ]]; then
      export MODE="createChannel"
      shift
  fi
fi

while [[ $# -ge 1 ]]; do
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

if [ ! -d ".dist/organizations/peer-organizations" ]; then
  CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
  CRYPTO_MODE=""
fi

if [ "$MODE" == "up" ]; then
  infoln "Starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}' ${CRYPTO_MODE}"
  networkUp
elif [ "$MODE" == "createChannel" ]; then
  infoln "Creating channel '${CHANNEL_NAME}'."
  infoln "If network is not up, starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE} ${CRYPTO_MODE}"
  createChannel
elif [ "$MODE" == "down" ]; then
  infoln "Stopping network"
  networkDown
elif [ "$MODE" == "restart" ]; then
  infoln "Restarting network"
  networkDown
  networkUp
elif [ "$MODE" == "deployCC" ]; then
  infoln "deploying chaincode on channel '${CHANNEL_NAME}'"
  deployCC
elif [ "$MODE" == "deployCCAAS" ]; then
  infoln "deploying chaincode-as-a-service on channel '${CHANNEL_NAME}'"
  deployCCAAS
else
  printHelp
  exit 1
fi
