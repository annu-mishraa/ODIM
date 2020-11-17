#!/bin/bash
declare PID=0

add_host()
{
        /bin/add-hosts -file /tmp/host.append
        if [ $? -ne 0 ]; then
                echo "Appending host entry to /etc/hosts file Failed"
                exit 0
        fi
}

sigterm_handler()
{
        if [[ $PID -ne 0 ]]; then
                # will wait for other instances to gracefully announce quorum exit
                sleep 5
                kill -9 $PID
                wait "$PID" 2>/dev/null
        fi
        exit 0
}

# create a signal trap
create_signal_trap()
{
        trap 'echo "[$(date)] -- INFO  -- SIGTERM received for account_session, initiating shut down"; sigterm_handler' SIGTERM
}

# keep the script running till SIGTERM is received
run_forever()
{
        wait
}

start_account_session()
{
	cd /bin
	export CONFIG_FILE_PATH=/etc/odimra_config/odimra_config.json
	nohup ./svc-account-session --registry=consul --registry_address=consul:8500 --server_address=account-session:45101 --client_request_timeout=`expr $(cat $CONFIG_FILE_PATH | grep SouthBoundRequestTimeoutInSecs | cut -d : -f2 | cut -d , -f1 | tr -d " ")`s >> /var/log/odimra_logs/account_session.log 2>&1 &
	PID=$!
	sleep 2s
}

monitor_process()
{
        while true; do
                pid=$(pgrep svc-account-session 2> /dev/null)
                if [[ $pid -eq 0 ]]; then
                        echo "svc-account-session has exited"
                        exit 1
                fi
                sleep 5
        done &
}

##############################################
###############  MAIN  #######################
##############################################

add_host

start_account_session

create_signal_trap

monitor_process

run_forever

exit 0
