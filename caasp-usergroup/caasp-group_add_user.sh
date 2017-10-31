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
  echo "USAGE: ${0} -u <username> -g <group name> -a <caasp admin server adress> [-A \"<caasp LDAP admin user>\"] [-w \"<caasp LDAP admin password>\"]"
  echo
  exit
}

get_user_group_info() {
  if [ -z ${CAASP_USER_NAME} ]
  then
    CAASP_USER_NAME="$(echo $* | grep -o "\-u [a-zA-Z0-9]*" | cut -d \  -f 2)" 
  fi

  if [ -z ${CAASP_LDAP_USER_DN} ]
  then
    CAASP_LDAP_USER_DN="uid=${CAASP_USER_NAME},${CAASP_LDAP_USER_BASE_DN}" 
  fi

  if [ -z ${CAASP_GROUP_NAME} ]
  then
    CAASP_GROUP_NAME=$(echo ${*} | grep -o "\-g [a-zA-Z0-9._/+-]*" | cut -d \  -f 2)
  fi

  if [ -z ${CAASP_LDAP_GROUP_DN} ]
  then
    CAASP_LDAP_GROUP_DN="cn=${CAASP_GROUP_NAME},${CAASP_LDAP_GROUP_BASE_DN}" 
  fi

  #echo
  #echo "CAASP_ADMIN_NODE=${CAASP_ADMIN_NODE}" 
  #echo "CAASP_LDAP_ADMIN_USER=${CAASP_LDAP_ADMIN_USER}" 
  #echo "CAASP_LDAP_ADMIN_DN=${CAASP_LDAP_ADMIN_DN}" 
  #echo "CAASP_LDAP_ADMIN_PASSWD=${CAASP_LDAP_ADMIN_PASSWD}" 
  #echo
  #echo "CAASP_GROUP_NAME=${CAASP_GROUP_NAME}" 
  #echo "CAASP_LDAP_GROUP_DN=${CAASP_LDAP_GROUP_DN}" 
  #echo
  #echo "CAASP_USER_NAME=${CAASP_USER_NAME}" 
  #echo "CAASP_LDAP_USER_DN=${CAASP_LDAP_USER_DN}" 
  #echo
}

add_ldap_user_to_group() {
  #echo "  -adding user to group ..."
  export LDAPTLS_REQCERT=never

  if ldapsearch -H ldap://"${CAASP_ADMIN_NODE}":389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w "${CAASP_LDAP_ADMIN_PASSWD}" -b ${CAASP_LDAP_GROUP_BASE_DN} "(cn=${CAASP_GROUP_NAME})" -LLL | grep ^uniqueMember | grep -q ${CAASP_LDAP_USER_DN}
  then
    echo
    echo "ERROR: The user is already in the group. Skipping."
  else
    local TMP_LDIF=/tmp/addusertoldapgrp.ldif
    ldapsearch -H ldap://"${CAASP_ADMIN_NODE}":389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w "${CAASP_LDAP_ADMIN_PASSWD}" -b ${CAASP_LDAP_GROUP_BASE_DN} "(cn=${CAASP_GROUP_NAME})" -LLL > ${TMP_LDIF}
    sed -i '/^$/d' ${TMP_LDIF}
    echo "uniqueMember: ${CAASP_LDAP_USER_DN}" >> ${TMP_LDIF}
    #echo
    #cat ${TMP_LDIF}
    #read  
    ldapdelete -H ldap://${CAASP_ADMIN_NODE}:389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w ${CAASP_LDAP_ADMIN_PASSWD} ${CAASP_LDAP_GROUP_DN} 
    ldapadd -H ldap://${CAASP_ADMIN_NODE}:389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w ${CAASP_LDAP_ADMIN_PASSWD} -f ${TMP_LDIF}

    #echo "cn: ${CAASP_LDAP_GROUP_DN}" > ${TMP_LDIF}
    #echo "changetype: modify" >> ${TMP_LDIF}
    #echo "add: uniqueMember" >> ${TMP_LDIF}
    #echo "uniqueMember: ${CAASP_LDAP_USER_DN}" >> ${TMP_LDIF}
    #echo
    #cat ${TMP_LDIF}
    #read 
    #ldapmodify -H ldap://"${CAASP_ADMIN_NODE}":389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w "${CAASP_LDAP_ADMIN_PASSWD}" -f ${TMP_LDIF}

      case $? in
        0)
           echo
           echo "User successfully added to group"
        ;;
        *)
           echo
           echo "There was an error adding the user to the group"
        ;;
      esac
 
    rm -f ${TMP_LDIF}
  fi 
}

main() {
  if [ -z ${1} ]
  then
    usage
  fi
  
  get_global_vars $*

  get_user_group_info $*
  echo
  echo "Adding user: ${CAASP_USER_NAME} (${CAASP_LDAP_USER_DN})"
  echo "to group: ${CAASP_GROUP_NAME} (${CAASP_LDAP_GROUP_DN})"

  add_ldap_user_to_group $*
  echo
}

###############################################################################

main $*
