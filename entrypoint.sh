#!/bin/bash

# If the docker socket has been mounted then ensure jenkins has permissions to it
if [ -e /var/run/docker.sock ]; then
  # Get the ID of the group that owns the socket
  DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)

  # Remove any existing group named docker
  /usr/bin/getent group docker 2>&1 > /dev/null && delgroup docker

  # Add a group named docker with the correct GID
  addgroup -g ${DOCKER_GID} docker

  # Add jenkins user to this group
  adduser jenkins docker
fi

# Switch back to Jenkins user and handoff to typical Jenkins entrypoint with all paramters
exec su jenkins -c "/sbin/tini -- /usr/local/bin/jenkins.sh $@"
