#!/bin/bash

pid=$(pgrep 'rbbc')
localHeight=$(curl -s localhost:8080/metrics | grep -v "#" | grep rbn_database_chaindb_height | awk '{print $2}')
netHeight=$(echo $(( 16#$(curl -s https://rbn-azure-australiasoutheast-1-0-b.devnet.redbelly.network:8545/ -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' | jq -r .result.number | sed 's/0x//') )) )
type="-"
ver="-"
network="devnet"
isGovernor=$(cat ~/rb/logs/rbbcLogs | grep "IsGovernor" | tail -1 | awk -F 'IsGovernor: ' '{print $2}' | cut -d '"' -f 1)

if (( $localHeight == $netHeight )); then status="ok";note="governor:$isGovernor"; else status="warning";note=" syncing $localHeight/$netHeight"; fi
if [ -z $pid ]; then status="error";note="not running"; fi
foldersize=$(du -hs ~/rb | awk '{print $1}')
logsize=$(du -hs ~/rb/logs/rbbcLogs | awk '{print $1}')

echo "updated='$(date +'%y-%m-%d %H:%M')'"
echo "version='$ver'"
echo "process='$pid'"
echo "status="$status
echo "note='$note'"
echo "network='$network'"
echo "type="$type
echo "folder="$foldersize
echo "log="$logsize
echo "governor=$isGovernor"
