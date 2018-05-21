#!/bin/bash

OPENLDAP_CONTAINER_ID=$(ssh root@admin docker ps | grep openldap | awk '{ print $1 }')

#ssh -qt root@admin docker exec -i '$(docker ps | grep openldap | awk '{ print $1 }')' cat /var/lib/misc/infra-secrets/openldap-password
ssh -qt root@admin docker exec -i ${OPENLDAP_CONTAINER_ID} cat /var/lib/misc/infra-secrets/openldap-password | tee pass.txt
