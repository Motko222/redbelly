#!/bin/bash
source ~/.bash_profile

pid=$(pgrep 'rbbc')
rpc=https://rbn-gcp-australia-southeast1-a-0-b-v2.devnet.redbelly.network:8545
#localHeight=$(curl -s localhost:8080/metrics | grep -v "#" | grep rbn_database_chaindb_height | awk '{print $2}')
local_height=$(cat ~/rb/logs/rbbcLogs | grep "Imported new chain segment" | tail -1 | awk -F 'number":"' '{print $2}' | cut -d '"' -f 1)
net_height=$(echo $(( 16#$(curl -s $rpc -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' | jq -r .result.number | sed 's/0x//') )))
is_governor=$(cat ~/rb/logs/rbbcLogs | grep "IsGovernor" | tail -1 | awk -F 'IsGovernor: ' '{print $2}' | cut -d '"' -f 1)

if (( $local_height == $net_height )); then status="ok";message="governor:$is_governor"; else status="warning";message=" syncing $local_height/$net_height"; fi
if [ -z $pid ]; then status="error";note="not running"; fi
folder_size=$(du -hs ~/rb | awk '{print $1}')
log_size=$(du -hs ~/rb/logs/rbbcLogs | awk '{print $1}')
log1=$(cat ~/rb/logs/rbbcLogs | tail -1 | sed 's/\"/\\\"/g' )
id=$REDBELLY_ID
network=devnet
chain=devnet2

cat << EOF
{
  "id":"$id",
  "machine":"$MACHINE",
  "chain":"$chain",
  "type":"node",
  "status":"$status",
  "message":"$message",
  "is_governor":"$is_governor",
  "updated":"$(date --utc +%FT%TZ)",
  "folder_size":"$folder_size",
  "log_size":"$log_size",
  "local_height":"$local_height",
  "net_height":"$net_height",
  "logs": [
  { "message":"$(echo $log1)" }
  ]
}
EOF

# send data to influxdb
if [ ! -z $INFLUX_HOST ]
then
 curl --request POST \
 "$INFLUX_HOST/api/v2/write?org=$INFLUX_ORG&bucket=$INFLUX_BUCKET&precision=ns" \
  --header "Authorization: Token $INFLUX_TOKEN" \
  --header "Content-Type: text/plain; charset=utf-8" \
  --header "Accept: application/json" \
  --data-binary "
    report,id=$id,machine=$MACHINE,grp=$group status=\"$status\",message=\"$message\",version=\"$version\",url=\"$url\",chain=\"$chain\",network=\"$network\" $(date +%s%N) 
    "
fi
