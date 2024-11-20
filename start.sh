#!/bin/bash

systemctl restart redbelly.service
sleep 1
tail -n 100 -f /var/log/redbelly/rbn_logs/rbbc_logs.log
