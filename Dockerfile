# ------------------------------------------------------------------------------
# Trivadis - Part of Accenture, Platform Factory - Data Platforms
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ------------------------------------------------------------------------------
# Name.......: Dockerfile
# Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
# Editor.....: Stefan Oehrli
# Date.......: 2023.07.04
# Revision...: 0.1.0
# Purpose....: Dockerfile to build a openconnect image with SSH Deamon
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
FROM alpine:3.16
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
  bash \
  pwgen

# Create environment
# ------------------------------------------------------------------------------
RUN mkdir /var/run/sshd \
  && mkdir /vpn \
  && mkdir -p /etc/openconnect && \
  addgroup -S vpn && \
  adduser -g "VPN User" -S vpn -G vpn && \
  mkdir -p /home/vpn/.ssh /root/.ssh && \
  chmod 700 /home/vpn/.ssh /root/.ssh && \
  chown -R vpn:vpn /home/vpn/.ssh

# Update sshd configuration
# ------------------------------------------------------------------------------
RUN sed -i 's/.*HostBasedAuthentication.*/HostBasedAuthentication no/gi'    /etc/ssh/sshd_config && \
    sed -i 's/.*MaxAuthTries.*/MaxAuthTries 5/g'                            /etc/ssh/sshd_config && \
    sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/g'                    /etc/ssh/sshd_config && \
    sed -i 's/.*X11Forwarding.*/X11Forwarding yes/g'                        /etc/ssh/sshd_config && \
    sed -i 's/.*X11UseLocalhost.*/X11UseLocalhost no/g'                     /etc/ssh/sshd_config && \
    sed -i 's/.*PermitTunnel no no/PermitTunnel yes/'                       /etc/ssh/sshd_config && \
    sed -i 's/.*AllowTcpForwarding no/AllowTcpForwarding yes/'              /etc/ssh/sshd_config && \
    sed -i 's/.*GatewayPorts no/GatewayPorts yes/'                          /etc/ssh/sshd_config

COPY  entrypoint.sh /
EXPOSE 22

VOLUME ["/vpn", "/etc/openconnect"]

ENTRYPOINT ["/entrypoint.sh"]
# --- EOF ----------------------------------------------------------------------
