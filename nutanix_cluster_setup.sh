#!/bin/bash
##############################################################################
source ./cluster.env

# Create Cluster 
cluster -s $CVM_IPS \
--dns_servers=$DNS_SERVERS \
--ntp_servers=$NTP_SERVERS \
--redundancy_factor=2 \
--cluster_name=$CLUSTER_NAME \
--cluster_external_ip=$CLUSTER_VIP create

sleep 60

# Time Zone
ncli cluster set-timezone timezone=$TIMEZONE force=true

# Set new Admin password
ncli user reset-password user-name=admin password="$NEW_PRIM_PASSWD"

# Cluster IP, Data Services IP
ncli cluster edit-info external-ip-address=$CLUSTER_VIP
#ncli cluster edit-params external-data-services-ip-address=$DATA_SVC_IP

# NTP
ncli cluster add-to-ntp-servers servers="$NTP_SERVERS"

# DNS
ncli cluster add-to-name-servers servers="$DNS_SERVERS"

# HTTP-PROXY
ncli http-proxy add name=$HTTP_PROXY_NAME address=$HTTP_PROXY_ADDRESS port=$HTTP_PROXY_PORT proxy-types=$HTTP_PROXY_TYPES

# Pulse 
curl -H "Content-Type: application/json" -X PUT -H "X-Nutanix-Preauth-User:admin" --data '{"enable": true,"identificationInfoScrubbingLevel": "ALL"}' http://localhost:9080/PrismGateway/services/rest/v1/pulse?proxyClusterUuid=all_clusters

# Network Visualization
ncli net add-snmp-profile community="$COMMUNITY" name="$SNMP_PROFILE_NAME" version=snmpv2c
ncli net add-switch-config snmp-profile-name="$SNMP_PROFILE_NAME" switch-address="$SWITCH_ADDRESS" host-addresses=$HOST_ADDRESSES

# VLAN
##
#acli net.create <VLAN name> vlan=<VLAN ID>

# Storage 
## rename storage pool
default_storage_pool=`ncli sp list | grep -i name | awk '{print $3}'`
ncli sp update name=$default_storage_pool new-name=$STORAGE_POOL_NAME

## Delete default conntainer 
default_container=`ncli ctr list | grep -i VStore | grep -i default | awk '{print $4}'`
ncli ctr remove name=$default_container

##create a new conntainer with specified name
ncli ctr create name=$CONTAINER_NAME rf=2 sp-name=$STORAGE_POOL_NAME enable-compression=true compression-delay=0
