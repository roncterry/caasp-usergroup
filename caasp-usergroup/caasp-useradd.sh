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
      echo
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
  echo "USAGE: ${0} -u <username> -F <first/given name> -L <last name/surname> [-P \"<plaintext password>\" | -p \"<password hash>\"] -E <email address> -g <group name> -a <caasp admin server adress> [-A \"<caasp LDAP admin user>\"] [-w \"<caasp LDAP admin password>\"]"
  echo
  exit
}

get_user_info() {
  if [ -z ${CAASP_USER_NAME} ]
  then
    CAASP_USER_NAME="$(echo $* | grep -o "\-u [a-zA-Z0-9]*" | cut -d \  -f 2)" 
    if [ -z ${CAASP_USER_NAME} ]
    then
      echo
      echo "ERROR: You must supply the user name for the new user."
      usage
      exit 1
    fi
  fi

  if [ -z ${CAASP_LDAP_USER_DN} ]
  then
    CAASP_LDAP_USER_DN="uid=${CAASP_USER_NAME},${CAASP_LDAP_USER_BASE_DN}" 
  fi

  if [ -z ${CAASP_USER_F_NAME} ]
  then
    CAASP_USER_F_NAME="$(echo $* | grep -o "\-F [a-zA-Z0-9]*" | cut -d \  -f 2)" 
    if [ -z ${CAASP_USER_F_NAME} ]
    then
      echo
      echo "ERROR: You must supply the first or given name for the new user."
      usage
      exit 1
    fi
  fi

  if [ -z ${CAASP_USER_L_NAME} ]
  then
    CAASP_USER_L_NAME="$(echo $* | grep -o "\-L [a-zA-Z0-9]*" | cut -d \  -f 2)" 
    if [ -z ${CAASP_USER_L_NAME} ]
    then
      echo
      echo "ERROR: You must supply the last name or surname of the new user."
      usage
      exit 1
    fi
  fi

  if [ -z ${CAASP_USER_PLAIN_PASSWD} ]
  then
    CAASP_USER_PLAIN_PASSWD="$(echo $* | grep -o "\-P [a-zA-Z0-9]*" | cut -d \  -f 2)" 
  fi

  if [ -z ${CAASP_USER_HASH_PASSWD} ]
  then
    CAASP_USER_HASH_PASSWD="$(echo $* | grep -o "\-p [a-zA-Z0-9]*" | cut -d \  -f 2)" 
  fi

  if [ -z ${CAASP_USER_EMAIL} ]
  then
    CAASP_USER_EMAIL="$(echo $* | grep -o "\-E [a-zA-Z0-9._%+@-]*" | cut -d \  -f 2)" 
    #CAASP_USER_EMAIL="$(echo $* | grep -io "\-E [A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}")" 
    if [ -z ${CAASP_USER_EMAIL} ]
    then
      echo
      echo "ERROR: You must supply the new user's email."
      usage
      exit 1
    fi
  fi

  if [ -z ${CAASP_GROUP_NAME} ]
  then
    CAASP_GROUP_NAME="$(echo $* | grep -o "\-g [a-zA-Z0-9._%+@$&*^#/-]*" | cut -d \  -f 2)" 
  fi

  if [ -z ${CAASP_LDAP_GROUP_DN} ]
  then
    CAASP_LDAP_GROUP_DN="cn=${CAASP_GROUP_NAME},${CAASP_LDAP_GROUP_BASE_DN}" 
  fi

  echo
  if [ -z ${1} ]
  then
    usage
    exit 1
  fi
  if [ -z ${CAASP_ADMIN_NODE} ]
  then
    echo "ERROR: You must supply the address for the CaaS Platform Admin node."
    usage
    exit 1
  fi
  if [ -z ${CAASP_USER_HASH_PASSWD} ]
  then
    if [ -z ${CAASP_USER_PLAIN_PASSWD} ]
    then
      echo "ERROR: You must supply a psssword either as plaintext using -P or as a hash using -p"
      echo
      exit
    else
      if [ -e /usr/sbin/slappasswd ]
      then
        CAASP_USER_HASH_PASSWD="$(/usr/sbin/slappasswd -s ${CAASP_USER_PLAIN_PASSWD})"
      else
        echo
        echo "ERROR: The command /usr/sbin/slappasswd does not appear to be installed."
        echo
        exit
      fi
    fi
  fi

  #echo "CAASP_ADMIN_NODE=${CAASP_ADMIN_NODE}" 
  #echo "CAASP_LDAP_ADMIN_USER=${CAASP_LDAP_ADMIN_USER}" 
  #echo "CAASP_LDAP_ADMIN_DN=${CAASP_LDAP_ADMIN_DN}" 
  #echo "CAASP_LDAP_ADMIN_PASSWD=${CAASP_LDAP_ADMIN_PASSWD}" 
  #echo
  #echo "CAASP_USER_NAME=${CAASP_USER_NAME}" 
  #echo "CAASP_LDAP_USER_DN=${CAASP_LDAP_USER_DN}" 
  #echo "CAASP_USER_F_NAME=${CAASP_USER_F_NAME}" 
  #echo "CAASP_USER_L_NAME=${CAASP_USER_L_NAME}" 
  #echo "CAASP_USER_PLAIN_PASSWD=${CAASP_USER_PLAIN_PASSWD}" 
  #echo "CAASP_USER_HASH_PASSWD=${CAASP_USER_HASH_PASSWD}" 
  #echo "CAASP_USER_EMAIL=${CAASP_USER_EMAIL}" 
  #echo "CAASP_GROUP_NAME=${CAASP_GROUP_NAME}" 
  #echo
}

create_user_ldif() {
  TMP_USER_LDIF=/tmp/newcaaspuser.ldif

  echo "
dn: ${CAASP_LDAP_USER_DN}
objectClass: person
objectClass: inetOrgPerson
objectClass: top
uid: ${CAASP_USER_NAME}
userPassword: $(/usr/sbin/slappasswd -s ${CAASP_USER_HASH_PASSWD})
givenname: ${CAASP_USER_F_NAME}
cn: ${CAASP_USER_F_NAME} ${CAASP_USER_L_NAME}
sn: ${CAASP_USER_L_NAME}
mail: ${CAASP_USER_EMAIL}
" > ${TMP_USER_LDIF}

#echo
#cat ${TMP_USER_LDIF}
#echo
}

add_ldap_user() {
    export LDAPTLS_REQCERT=never
    #echo "COMMAND: ldapadd -H ldap://${CAASP_ADMIN_NODE}:389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w ${CAASP_LDAP_ADMIN_PASSWD} -f ${TMP_USER_LDIF}"
    #read
    echo -n "  -"
    ldapadd -H ldap://${CAASP_ADMIN_NODE}:389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w ${CAASP_LDAP_ADMIN_PASSWD} -f ${TMP_USER_LDIF}

  case $? in
    0)
      echo "User created successfully."
      echo
      rm -f ${TMP_USER_LDIF}
    ;;
    *)
      echo
      echo "There was an error creating the user."
      echo
    ;;
  esac
}

add_ldap_user_to_group() {
  echo "  -adding user to group: ${CAASP_GROUP_NAME}"
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
    echo -n "   "
    ldapadd -H ldap://${CAASP_ADMIN_NODE}:389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w ${CAASP_LDAP_ADMIN_PASSWD} -f ${TMP_LDIF}

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
    exit 1
  fi
  
  get_global_vars $*
  
  get_user_info $*
  echo
  echo "Creating user: ${CAASP_USER_NAME} (${CAASP_LDAP_USER_DN})"
  echo

  create_user_ldif
  add_ldap_user

  if ! [ -z ${CAASP_GROUP_NAME} ]
  then
    if ldapsearch -H ldap://"${CAASP_ADMIN_NODE}":389 -ZZ -D ${CAASP_LDAP_ADMIN_DN} -w "${CAASP_LDAP_ADMIN_PASSWD}" -b ${CAASP_LDAP_GROUP_BASE_DN} "(cn=${CAASP_GROUP_NAME})" -LLL | grep -q "cn=${CAASP_GROP_NAME}"
    then
      add_ldap_user_to_group
    fi
  fi
  echo
}

###############################################################################

main $*
