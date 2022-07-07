#!/bin/bash

function enroll() {
  infoln "Enrolling the CA admin"
  mkdir -p "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com"

  export FABRIC_CA_CLIENT_HOME="${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com"

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca.orderer.mvg-sky.com --tls.certfiles "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer-mvg-sky-com.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer-mvg-sky-com.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer-mvg-sky-com.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer-mvg-sky-com.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/msp/config.yaml"

  mkdir -p "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/msp/tlscacerts"
  cp "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/fabric-ca/ca-cert.pem" "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/msp/tlscacerts/tlsca.orderer.mvg-sky.com-cert.pem"

  mkdir -p "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/tlsca"
  cp "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/fabric-ca/ca-cert.pem" "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/tlsca/tlsca.orderer.mvg-sky.com-cert.pem"

  # ======================================== ENROLL ORDERERS =========================================
    enrollOrderer 0
    enrollOrderer 1
    enrollOrderer 2
  # ==================================================================================================

  # ======================================== ENROLL ADMIN ============================================
  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca.orderer.mvg-sky.com --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca.orderer.mvg-sky.com -M "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/users/Admin@orderer.mvg-sky.com/msp" --tls.certfiles "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/msp/config.yaml" "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/users/Admin@orderer.mvg-sky.com/msp/config.yaml"
  # ==================================================================================================
}

function enrollOrderer() {
  local ORDERER="${1}"

  infoln "Registering orderer${ORDERER}"
  set -x
  fabric-ca-client register --caname ca.orderer.mvg-sky.com --id.name orderer${ORDERER} --id.secret orderer${ORDERER}pw --id.type orderer --tls.certfiles "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer${ORDERER} msp"
  set -x
  fabric-ca-client enroll -u https://orderer${ORDERER}:orderer${ORDERER}pw@localhost:9054 --caname ca.orderer.mvg-sky.com -M "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/msp" --csr.hosts orderer${ORDERER}.orderer.mvg-sky.com --csr.hosts localhost --tls.certfiles "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/msp/config.yaml" "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/msp/config.yaml"

  infoln "Generating the orderer${ORDERER}-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer${ORDERER}:orderer${ORDERER}pw@localhost:9054 --caname ca.orderer.mvg-sky.com -M "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/tls" --enrollment.profile tls --csr.hosts orderer${ORDERER}.orderer.mvg-sky.com --csr.hosts localhost --tls.certfiles "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/fabric-ca/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/tls/tlscacerts/"* "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/tls/ca.crt"
  cp "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/tls/signcerts/"* "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/tls/server.crt"
  cp "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/tls/keystore/"* "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/tls/server.key"

  mkdir -p "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/msp/tlscacerts"
  cp "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/tls/tlscacerts/"* "${PWD}/dist/organizations/ordererOrganizations/orderer.mvg-sky.com/orderers/orderer${ORDERER}.orderer.mvg-sky.com/msp/tlscacerts/tlsca.orderer.mvg-sky.com-cert.pem"
}
