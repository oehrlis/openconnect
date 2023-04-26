# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Data Platforms
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2023.04.26
# Revision...: 1.0
# Purpose....: Dockerfile to build a openconnect images
# Notes......: --
# Reference..: --
# License....: Apache License Version 2.0, January 2004 as shown
#              at http://www.apache.org/licenses/
# ------------------------------------------------------------------------------
# Modified...:
# see git revision history for more information on changes/updates
# ------------------------------------------------------------------------------

# Pull base image
# ------------------------------------------------------------------------------
FROM alpine:latest
ARG TARGETPLATFORM
ARG TARGETARCH

# Maintainer
# ------------------------------------------------------------------------------
LABEL maintainer="stefan.oehrli@accenture.com"

# Install required packages
# ------------------------------------------------------------------------------
RUN apk update && apk add --no-cache \
  gnutls \
  openssh \
  openconnect \
  curl \
  pwgen

RUN mkdir /var/run/sshd \
  && mkdir /vpn \
  && mkdir -p /etc/openconnect

# Configure SSHD
# ------------------------------------------------------------------------------
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin\ yes/' /etc/ssh/sshd_config
RUN sed -i 's/^AllowTcpForwarding no/AllowTcpForwarding yes/' /etc/ssh/sshd_config
RUN sed -i 's/^GatewayPorts no/GatewayPorts yes/' /etc/ssh/sshd_config
RUN sed -i 's/^#PermitTunnel no no/PermitTunnel yes/' /etc/ssh/sshd_config

COPY  entrypoint.sh /
EXPOSE 22

VOLUME ["/vpn", "/etc/openconnect"]

ENTRYPOINT ["/entrypoint.sh"]
# --- EOF ----------------------------------------------------------------------