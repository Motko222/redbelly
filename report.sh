#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/config

pid=$(pgrep 'rbbc')

# localHeight=$(curl -s localhost:8080/metrics | grep -v "#" | grep rbn_database_chaindb_height | awk '{print $2}')
#local_height=$(cat /var/log/redbelly/rbn_logs/rbbc_logs.log | grep "Imported new chain segment" | tail -1 | awk -F 'number": "' '{print $2}' | cut -d '"' -f 1)
local_height=$(cat /var/log/redbelly/rbn_logs/rbbc_logs.log | grep -a "Done processing block " | tail -1 | awk '{print $NF}')
#local_height=$(echo $(( 16#$(curl -s $LOCAL_RPC -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' | jq -r .result.number | sed 's/0x//') )))
net_height=$(echo $(( 16#$(curl -s $NET_RPC -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' | jq -r .result.number | sed 's/0x//') )))
is_governor=$(cat /var/log/redbelly/rbn_logs/rbbc_logs.log | grep -a "and is governor" | tail -1 | awk -F 'and is governor ' '{print $2}' | awk '{print $1}')
errors=$(cat /var/log/redbelly/rbn_logs/rbbc_logs.log | grep -a $(date +%Y-%m-%d) | grep -c ERROR)
behind=$(( $net_height - $local_height))
folder_size=$(du -hs /opt/redbelly | awk '{print $1}')
log_size=$(du -hs /var/log/redbelly | awk '{print $1}')

if [ $behind -le 5 ]
then
   status="ok" && message="governor:$is_governor"
else 
   status="warning" && message=" syncing $local_height/$net_height (behind $behind)"
fi
[ $errors -gt 100 ] && status="warning" && message="errors=$errors behind=$behind";
[ -z $pid ] && status="error" && note="process not running"


cd $INSTALL
version=$(./rbbc -v | awk '{print $3}')

cat >$json << EOF
{ 
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
        "id":"$folder",
        "machine":"$MACHINE",
        "owner":"$OWNER",
        "grp":"node" 
  },
  "fields": {
        "chain":"testnet",
        "network":"testnet",
        "status":"$status",
        "version":"$version",
        "message":"$message",
        "errors":"$errors",
        "is_governor":"$is_governor",
        "folder_size":"$folder_size",
        "log_size":"$log_size",
        "local_height":"$local_height",
        "net_height":"$net_height",
        "behind":"$behind"
  }
}
EOF

cat $json | jq
