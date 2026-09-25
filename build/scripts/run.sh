#!/usr/bin/env sh
# Overrides the base image's run.sh so a failing pre-init script (such as an
# invalid environment value) stops the container instead of being ignored.
for i in /scripts/pre-init.d/*sh
do
  if [ -e "${i}" ]; then
    SCRIPT_NAME=$(basename $i)
    START_TIME=$(date +%s)
    echo "[i] pre-init.d - $SCRIPT_NAME..."
    if ! "${i}"; then
      echo "[!] pre-init.d - $SCRIPT_NAME failed. Stopping container."
      exit 1
    fi
    FINISH_TIME=$(date +%s)
    STARTUP_TIME=$(expr $FINISH_TIME - $START_TIME)
    echo "${SCRIPT_NAME}|${STARTUP_TIME}" >> /tmp/deploy_step_times
  fi
done

$APP_STARTUP_CMD
