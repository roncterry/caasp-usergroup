# caasp-usergroup
SUSE CaaS Platform User and Group Management Utilities

## Description:
The caasp-usergroup utilities are a set of commands that allow you to more easily create, deleate and manage users and groups in a SUSE CasS Platform cluster. They are essentially scripts that wrap ldap commands into more easlily used commands who's syntax is similar to the traditional linux useradd/groupadd/etc commands.

All commands can be configured using either command line options and/or variables set in a **_caasp-usergoup.rc_** file that is sources into the shell environment.

## Commands:

**caasp-useradd.sh**

* Creates new users in the local LDAP directory.

**caasp-userdel.sh**

* Deletes users from the local LDAP directory.

**caasp-groupadd.sh**
* Creates new groups in the local LDAP directory.

**caasp-groupdel.sh**
* Deletes groups from the local LDAP directory.

**caasp-group_add_users.sh**
* Add users to groups in the local LDAP directory.

**caasp-group_remove_users.sh**
* Remove users from groups in the local LDAP directory.

**caasp-userlist.sh**
* List all users in the local LDAP directory.

**caasp-usershow.sh**
* Display information about a user in the local LDAP direcotory sudh as username, first and last names, email, etc.

**caasp-grouplist.sh**
* Display all groups in the local LDAP directory.

**caasp-groupshow.sh**
* Display information about a group in the local LDAP directory such as group members.

**get-caasp-ldap-admin-pw.sh**
* Retrieve the local LDAP administrator user's password.


## Requirements:
The caasp-usergroup utilities require the standard ldap client commands (ldapadd, ldapdelete, etc. from the openldap2-client package) along with the slappasswd command (from the openldap2 package) to be installed .
