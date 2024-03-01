#!/bin/bash

pid=$(pgrep 'rbbc')
#localHeight=$(curl -s localhost:8080/metrics | grep -v "#" | grep rbn_database_chaindb_height | awk '{print $2}')
local_height=$(cat ~/rb/logs/rbbcLogs | grep "Imported new chain segment" | tail -1 | awk -F 'number":"' '{print $2}' | cut -d '"' -f 1)
net_height=$(echo $(( 16#$(curl -s https://rbn-gcp-australia-southeast1-a-0-b-v2.devnet.redbelly.network:8545/ -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' | jq -r .result.number | sed 's/0x//') )) )
network="devnet2"
is_governor=$(cat ~/rb/logs/rbbcLogs | grep "IsGovernor" | tail -1 | awk -F 'IsGovernor: ' '{print $2}' | cut -d '"' -f 1)

if (( $local_height == $net_height )); then status="ok";note="governor:$is_governor"; else status="warning";note=" syncing $local_height/$net_height"; fi
if [ -z $pid ]; then status="error";note="not running"; fi
folder_size=$(du -hs ~/rb | awk '{print $1}')
log_size=$(du -hs ~/rb/logs/rbbcLogs | awk '{print $1}')
log=$(cat ~/rb/logs/rbbcLogs | tail -5)

cat << EOF
{
  "project":"$folder",
  "id":$ID,
  "machine":"$MACHINE",
  "chain":"devnet2",
  "type":"node",
  "status":"$status",
  "note":"$note",
  "updated":"$(date --utc +%FT%TZ)",
  "folder_size":"$folder_size",
  "log_size":"$log_size",
  "logs": 
  { "message":"$(echo $logs | tail -1 | head -1')",
    "message":"$(echo $logs | tail -2 | head -1')",
    "message":"$(echo $logs | tail -3 | head -1')" }
}
EOF
