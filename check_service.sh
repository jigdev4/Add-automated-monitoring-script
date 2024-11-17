#!/bin/bash

SERVICE="nginx"  # Change to "apache2" if using Apache
LOG_FILE="/var/log/service_status.log"
BACKUP_DIR="/var/backups/$SERVICE"
CPU_THRESHOLD=80
EMAIL="destinyobueh14@gmail.com"

# Check if the web server service is running
if ! systemctl is-active --quiet $SERVICE; then
    echo "$(date): $SERVICE is down" >> $LOG_FILE

    # Backup configuration files
    mkdir -p $BACKUP_DIR
    CONFIG_BACKUP="$BACKUP_DIR/${SERVICE}_config_$(date +'%Y%m%d%H%M%S').tar.gz"
    tar -czf $CONFIG_BACKUP /etc/$SERVICE/

    # Attempt to restart the service
    sudo  systemctl restart $SERVICE
    sleep 2  # Pause to allow the service to restart

    # Check if restart was successful
    if ! systemctl is-active --quiet $SERVICE; then
        echo "$(date): $SERVICE failed to restart" >> $LOG_FILE
        echo -e "Subject: $SERVICE Alert!\n\n$SERVICE on $(hostname) is down and could not be restarted" | ssmtp $EMAIL
	echo -e "Subject: $SERVICE Alert!\n\n$SERVICE on $(hostname) restarted successfully" | ssmtp $EMAIL
    else
        echo "$(date): $SERVICE restarted successfully" >> $LOG_FILE
    fi
else
    echo "$(date): $SERVICE is running" >> $LOG_FILE
fi

# Monitor CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
if (( ${CPU_USAGE%.*} > CPU_THRESHOLD )); then
    echo "$(date): CPU usage is at ${CPU_USAGE}%, which exceeds the threshold of ${CPU_THRESHOLD}%" >> $LOG_FILE
fi


