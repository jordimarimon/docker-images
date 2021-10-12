# This image exists because of this: https://github.com/nodejs/docker-node/issues/586

FROM node:16.9.1-alpine3.11

# Update packages
RUN apk update && apk upgrade

# Install base dependencies
# See: https://pkgs.alpinelinux.org/packages
RUN apk add --no-cache bash git openssh jq

WORKDIR /opt/ci/agent/build

ENTRYPOINT /bin/bash
