#!/bin/bash

APP_NAME=CodeDeployDemo-0.0.1-SNAPSHOT.jar
APP_DIR=/home/ec2-user/app
LOG_FILE=$APP_DIR/app.log

# Kill existing app
PID=$(pgrep -f "$APP_NAME")
if [ -n "$PID" ]; then
  echo "Stopping existing application with PID $PID"
  kill -9 $PID
fi

# Wait for the process to stop
sleep 2

# Start new application
echo "Starting new application..."
nohup java -jar $APP_DIR/$APP_NAME > $LOG_FILE 2>&1 &
