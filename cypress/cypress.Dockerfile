# NodeJS images available: https://hub.docker.com/_/node
# We use as OS "bullseye" (Debian 11: https://www.debian.org/releases/bullseye/)
# Chrome seems to only support Ubuntu or >= Debian 10
# See: https://chromium.googlesource.com/chromium/src/+/refs/heads/main/build/install-build-deps.sh#108
FROM node:16.9.1-bullseye

# Set user as root
USER root

######################################################
######## ENVIRONMENT VARIABLES
######################################################

# A few environment variables to make NPM installs easier
# good colors for most applications
ENV TERM xterm
# Avoid million NPM install messages
ENV npm_config_loglevel warn
# Allow installing when the main user is root
ENV npm_config_unsafe_perm true
# Chrome version
ENV CHROME_VERSION 93.0.4577.82
# Firefox version
ENV FIREFOX_VERSION 92.0
# "fake" dbus address to prevent errors
# https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null

######################################################
######## INSTALL DEPENDENCIES
######################################################

# Update packages
RUN apt-get -y update && apt-get -y autoremove && apt-get clean

# Install cypress dependencies
# See: https://docs.cypress.io/guides/getting-started/installing-cypress#System-requirements
# Install also chrome dependencies ("fonts-liberation" and "xdg-utils" -> if we don't install them, the chrome installation will break)
# Only install the main dependencies (packages in the Depends field)
RUN apt-get install --no-install-recommends -y \
    libgtk2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libnotify-dev \
    libgconf-2-4 \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    xauth \
    xvfb \
    fonts-liberation \
    xdg-utils

# Clean up
RUN rm -rf /var/lib/apt/lists/*

# Need to update before the below installs or the below packages won't be found
RUN apt-get -y update

# Add zip utility - it comes in very handy
RUN apt-get install -y zip

# add codecs needed for video playback in firefox
# https://github.com/cypress-io/cypress-docker-images/issues/150
RUN apt-get install -y mplayer

# Install npm
RUN npm install -g npm@latest

# Install Chrome
RUN wget -O /usr/src/google-chrome-stable_current_amd64.deb "http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb" && \
  dpkg -i /usr/src/google-chrome-stable_current_amd64.deb ; \
  apt-get install -f -y && \
  rm -f /usr/src/google-chrome-stable_current_amd64.deb

# Install Firefox
RUN wget --no-verbose -O /tmp/firefox.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2 \
  && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
  && rm /tmp/firefox.tar.bz2 \
  && ln -fs /opt/firefox/firefox /usr/bin/firefox

# Install Edge (it's not really needed because it uses chromium...)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-beta.list' && \
    rm microsoft.gpg && \
    apt-get update -y && \
    apt-get install -y microsoft-edge-beta

# TODO(Jordi M.): Install Webkit (use playwright or Epiphany?)

# Print versions of local tools
RUN echo "Node version:    $(node -v)" && \
    echo "NPM version:     $(npm -v)" && \
    echo "Debian version:  $(cat /etc/debian_version)" && \
    echo "Chrome version:  $(google-chrome --version)" && \
    echo "Firefox version: $(firefox --version)" && \
    echo "Edge version:    $(microsoft-edge --version)" && \
    echo "Git version:     $(git --version)" && \
    echo "WHOAMI:          $(whoami)"
