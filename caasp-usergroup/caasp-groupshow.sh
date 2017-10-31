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
  echo "USAGE: ${0} -g <caasp group name> -a <caasp admin server adress> [-A \"<caasp LDAP admin user>\"] [-w \"<caasp LDAP admin password>\"]"
  echo
  exit
}

get_user_info() {
  if [ -z ${CAASP_GROUP_NAME} ]
  then
    CAASP_GROUP_NAME=$(echo ${*} | grep -o "\-g [a-zA-Z0-9._/+-]*" | cut -d \  -f 2)
  fi

  if [ -z ${CAASP_LDAP_GROUP_DN} ]
  then
    CAASP_LDAP_GROUP_DN="cn=${CAASP_GROUP_NAME},${CAASP_LDAP_GROUP_BASE_DN}" 
  fi

  #echo "CAASP_ADMIN_NODE=${CAASP_ADMIN_NODE}" 
  #echo "CAASP_LDAP_ADMIN_USER=${CAASP_LDAP_ADMIN_USER}" 
  #echo "CAASP_LDAP_ADMIN_DN=${CAASP_LDAP_ADMIN_DN}" 
  #echo "CAASP_LDAP_ADMIN_PASSWD=${CAASP_LDAP_ADMIN_PASSWD}" 
  #echo "CAASP_GROUP_NAME=${CAASP_GROUP_NAME}"

}

show_caasp_group() {
  echo
  export LDAPTLS_REQCERT=never 
  ldapsearch \
  -H ldap://"${CAASP_ADMIN_NODE}":389 \
  -ZZ \
  -D cn="${CAASP_LDAP_ADMIN_USER}",${CAASP_LDAP_BASE_DN} \
  -w "${CAASP_LDAP_ADMIN_PASSWD}" \
  -b ${CAASP_LDAP_GROUP_BASE_DN} \
  "(cn=${CAASP_GROUP_NAME})" \
  -LLL cn uniqueMember \
  | grep -v ^dn: \
  | grep -v ^cn:: \
  | sed 's/cn:/Group Name:/g' \
  | sed 's/uniqueMember/Member/g' \
  | sed 's/uid=//g' \
  | sed 's/cn=//g' \
  | cut -d , -f 1
}

main() {
  if [ -z ${1} ]
  then
    usage
    exit 1
  fi

  get_global_vars $*
  get_user_info $*
  show_caasp_group $*
}

###############################################################################

main $*
