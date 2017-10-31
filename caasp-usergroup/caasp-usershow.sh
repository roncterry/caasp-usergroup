#!/bin/bash

###############################################################################
#      Global Vars
###############################################################################

get_global_vars() {
  if [ -z ${CAASP_LDAP_BASE_DN} ]
  then
    CAASP_LDAP_BASE_DN="dc=infra,dc=caasp,dc=local"
  fi

  if [ -z ${CAASP_LDAP_USER_BASE_DN} ]
  then
    CAASP_LDAP_USER_BASE_DN="ou=People,${CAASP_LDAP_BASE_DN}"
  fi

  if [ -z ${CAASP_LDAP_GROUP_BASE_DN} ]
  then
    CAASP_LDAP_GROUP_BASE_DN="ou=Groups,${CAASP_LDAP_BASE_DN}"
  fi

  if [ -z ${CAASP_LDAP_ADMIN_GROUP_DN} ]
  then
    CAASP_LDAP_ADMIN_GROUP_DN="ou=Administrators,${CAASP_LDAP_GROUP_BASE_DN}"
  fi

  if [ -z ${CAASP_LDAP_ADMIN_GROUP_NAME} ]
  then
    CAASP_LDAP_ADMIN_GROUP_NAME="Administrators"
  fi

  if [ -z ${CAASP_ADMIN_NODE} ]
  then
    CAASP_ADMIN_NODE="$(echo $* | grep -o "\-a [a-zA-Z0-9\.]*" | cut -d \  -f 2)" 
    if [ -z ${CAASP_ADMIN_NODE} ]
    then
      echo "ERROR: You must supply the address for the CaaS Platform Admin node."
      usage
      exit 1
    fi
  fi

  if [ -z ${CAASP_LDAP_ADMIN_USER} ]
  then
    CAASP_LDAP_ADMIN_USER="$(echo $* | grep -o "\-A [a-zA-Z0-9._%+@$&*^#/-]*" | cut -d \  -f 2)" 
    if [ -z ${CAASP_LDAP_ADMIN_USER} ]
    then
      CAASP_LDAP_ADMIN_USER=admin
    fi
  fi

  if [ -z ${CAASP_LDAP_ADMIN_DN} ]
  then
    CAASP_LDAP_ADMIN_DN="cn=${CAASP_LDAP_ADMIN_USER},${CAASP_LDAP_BASE_DN}"
  fi

  if [ -z ${CAASP_LDAP_ADMIN_PASSWD} ]
  then
    CAASP_LDAP_ADMIN_PASSWD="$(echo $* | grep -o "\-w [a-zA-Z0-9._%+@$&*^#/-]*" | cut -d \  -f 2)" 
    if [ -z ${CAASP_LDAP_ADMIN_PASSWD} ]
    then
      echo -n "Enter LDAP password: "; read CAASP_LDAP_ADMIN_PASSWD
    fi
  fi
}

###############################################################################
#      Functions
###############################################################################

usage() {
  echo
  echo "USAGE: ${0} -g <caasp username> -a <caasp admin server adress> [-A \"<caasp LDAP admin user>\"] [-w \"<caasp LDAP admin password>\"]"
  echo
  exit
}

get_user_info() {
  if [ -z ${CAASP_USER_NAME} ]
  then
    CAASP_USER_NAME=$(echo ${*} | grep -o "\-u [a-zA-Z0-9]*" | cut -d \  -f 2)
  fi

  if [ -z ${CAASP_LDAP_USER_DN} ]
  then
    CAASP_LDAP_USER_DN="uid=${CAASP_USER_NAME},${CAASP_LDAP_USER_BASE_DN}" 
  fi

  #echo "CAASP_ADMIN_NODE=${CAASP_ADMIN_NODE}" 
  #echo "CAASP_LDAP_ADMIN_USER=${CAASP_LDAP_ADMIN_USER}" 
  #echo "CAASP_LDAP_ADMIN_DN=${CAASP_LDAP_ADMIN_DN}" 
  #echo "CAASP_LDAP_ADMIN_PASSWD=${CAASP_LDAP_ADMIN_PASSWD}" 
  #echo "CAASP_USER_NAME=${CAASP_USER_NAME}"
}

show_caasp_user() {
  echo
  export LDAPTLS_REQCERT=never 
  ldapsearch \
  -H ldap://"${CAASP_ADMIN_NODE}":389 \
  -ZZ \
  -D cn="${CAASP_LDAP_ADMIN_USER}",${CAASP_LDAP_BASE_DN} \
  -w "${CAASP_LDAP_ADMIN_PASSWD}" \
  -b ${CAASP_LDAP_BASE_DN} \
  "(uid=${CAASP_USER_NAME})" \
  -LLL uid givenName sn mail | grep -v ^dn: | sed 's/uid/Username/g' | sed 's/givenName/First Name/g' | sed 's/sn/Last Name/g'
}

main() {
  if [ -z ${1} ]
  then
    usage
    exit 1
  fi

  get_global_vars $*
  get_user_info $*
  show_caasp_user $*
}

###############################################################################

main $*
