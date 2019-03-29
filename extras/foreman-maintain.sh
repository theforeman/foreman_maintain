#!/bin/bash 
function quit_if_in_maintenance_mode {
  /usr/bin/foreman-maintain maintenance-mode is-enabled
  if [ $? -eq 0 ]
  then
    echo "Maintenance mode is on can not continue"
    exit 1
  fi
}

function is_maintenance_mode_enabled {
  /usr/bin/foreman-maintain maintenance-mode is-enabled
  echo $?
}
