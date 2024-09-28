#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=~/logs/report-$folder
source ~/.bash_profile

pid=$(pgrep 'rbbc')
local_rpc=$REDBELLY_RPC
net_rpc=https://rbn-gcp-australia-southeast1-a-0-b-v2.devnet.redbelly.network:8545

# localHeight=$(curl -s localhost:8080/metrics | grep -v "#" | grep rbn_database_chaindb_height | awk '{print $2}')
#local_height=$(cat ~/rb/logs/rbbcLogs | grep "Imported new chain segment" | tail -1 | awk -F 'number":"' '{print $2}' | cut -d '"' -f 1)
local_height=$(echo $(( 16#$(curl -s $local_rpc -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' | jq -r .result.number | sed 's/0x//') )))
net_height=$(echo $(( 16#$(curl -s $net_rpc -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' | jq -r .result.number | sed 's/0x//') )))
is_governor=$(cat ~/rb/logs/rbbcLogs | grep "IsGovernor" | tail -1 | awk -F 'IsGovernor: ' '{print $2}' | cut -d '"' -f 1)

if (( $local_height == $net_height )); then status="ok";message="governor:$is_governor"; else status="warning";message=" syncing $local_height/$net_height"; fi
if [ -z $pid ]; then status="error";note="not running"; fi
folder_size=$(du -hs ~/rb | awk '{print $1}')
log_size=$(du -hs ~/rb/logs/rbbcLogs | awk '{print $1}')
#log1=$(cat ~/rb/logs/rbbcLogs | tail -1 | sed 's/\"/\\\"/g' )

cat >$json << EOF
{ 
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
        "id":"$folder",
        "machine":"$MACHINE",
        "owner":"$OWNER",
        "grp":"node" }
  "fields": {
        "chain":"devnet2",
        "network":"devnet",
        "status":"$status",
        "message":"$message",
        "is_governor":"$is_governor",
        "folder_size":"$folder_size",
        "log_size":"$log_size",
        "local_height":"$local_height",
        "net_height":"$net_height"
  }
}
EOF

cat $json | jq
