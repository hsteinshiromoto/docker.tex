#!/bin/bash
set -e

# If "-e uid={custom/local user id}" flag is not set for "docker run" command, use 9999 as default
CURRENT_UID=${uid:-9999}

# If "-e docker_user={custom/local user id}" flag is not set for "docker run" command, use docker_user as default
DOCKER_USER=${DOCKER_USER:-docker_user}

# TODO: How to add user without passwords?
CONTAINER_PASSWORD=1234

# Create user called "docker" with selected UID
useradd --shell /bin/bash -p $(openssl passwd -1 $CONTAINER_PASSWORD) -u $CURRENT_UID -o -c "" -m $DOCKER_USER

# Execute process
exec gosu $DOCKER_USER "$@"