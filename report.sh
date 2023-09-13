#!/bin/bash

        temp=$HOME/logs/redbelly.txt
        pid=$(pgrep 'rbbc')

        #temp1=$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' localhost:8545 \
        #   | jq -r .result.number | sed 's/0x//')
        #if [ -z $temp1 ]; then l2height="err"; else l2height=$(( 16#$temp1 )); fi
        #localHeight=$(cat $HOME/rb/logs/rbbcLogs | grep "Imported new chain segment" | tail -1 | awk -F 'number": "' '{print $2}' | cut -d '"' -f 1)
        localHeight=$(curl -s localhost:8080/metrics | grep -v "#" | grep rbn_database_chaindb_height | awk '{print $2}')
        netHeight=$(echo $(( 16#$(curl -s https://rbn-azure-australiasoutheast-1-0-b.devnet.redbelly.network:8545/ -X POST -H "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":1,"jsonrpc":"2.0"}' | jq -r .result.number | sed 's/0x//') )) )
        type="-"
        ver="-"
        network="devnet"
        isGovernor=$(cat $HOME/rb/logs/rbbcLogs | grep "IsGovernor" | tail -1 | awk -F 'IsGovernor: ' '{print $2}' | cut -d '"' -f 1)

        if (( $localHeight == $netHeight )); then status="ok";note="governor:$isGovernor"; else status="warning";note=" syncing $localHeight/$netHeight"; fi
        if [ -z $pid ]; then status="error";note="not running"; fi
        foldersize=$(du -hs $HOME/rb | awk '{print $1}')
        logsize=$(du -hs $HOME/rb/logs/rbbcLogs | awk '{print $1}')

        echo "--- REDBELLY ----------------------"
        localHeightecho "updated:            "$now
        echo "version:            "$ver
        echo "process:            "$pid
        echo "status:             "$status
        echo "note:               "$note
        echo "network:            "$network
        echo "type:               "$type
        echo "folder size:        "$foldersize
        echo "log size:           "$logsize
        echo "local height:       "$localHeight
        echo "network height:     "$netHeight
        echo "is governor:        "$isGovernor

        echo "updated='"$now"'" >$temp
        echo "version='"$ver"'" >>$temp
        echo "process='"$pid"'" >>$temp
        echo "status="$status >>$temp
        echo "note='"$note"'" >>$temp
        echo "network='"$network"'" >>$temp
        echo "type="$type >>$temp
        echo "folder="$foldersize >>$temp
        echo "log="$logsize >>$temp
        cp $temp $report
