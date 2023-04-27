# OpenConnect Container

[![Build and publish image to Docker](https://github.com/oehrlis/openconnect/actions/workflows/dockerhub_build.yml/badge.svg)](https://github.com/oehrlis/openconnect/actions/workflows/dockerhub_build.yml)

## General Informations

This is a simple container providing *OpenConnect* together with SSH.

- VPN connection to your corporate network via [OpenConnect](https://github.com/openconnect).
  *OpenConnect* can connect to AnyConnect, Pulse and PAN.
- SSH server to allow port forwarding via *OpenConnect*
- The container starts in [privileged](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)
  mode in order to avoid the *read-only file system*
  [error](https://serverfault.com/questions/878443/when-running-vpnc-in-docker-get-cannot-open-proc-sys-net-ipv4-route-flush).
  Please proceed with your own **risk**.

## Build

Local manual build of the Docker image.

```bash
git clone https://github.com/oehrlis/openconnect.git
cd openconnect
docker build -t oehrlis/openconnect .
```

## Run

### Configuration

The main configuration file *vpd.config*, contain the following values:

- **SERVER**: VPN endpoint
- **AUTHGROUP**: VPN Authentication Group
- **USERNAME**: VPN Login username
- **DYNAMIC_TOKEN**: *TRUE* if dynamic OTP is required, *FALSE* otherwise. Setting
  this variable will clears the file *vpdtoken* after reading.
- **OPTIONS**: Additional options for *OpenConnect*

### Environment variables

The environment variables required to run the container

- `DOCKER_VOLUME_BASE`: If set, the SOCKS5 proxy is enabled and exposed through this port
- `SSH_PORT`: If set, the HTTP proxy is enabled and exposed through this port

These variables can be specified in the command line or in the *.env* file in the
case of *docker-compose*.

### Providing the VPN Password

The VPN password is read from file `/vpn/token` within the container. Simply configure
the password outside the container using:

```bash
echo VPN_PASSWORD > ./vpnpasswd
```

### Providing the OTP token

A token is taken from the file `/vpn/token` within the container. If *DYNAMIC_TOKEN*
is *TRUE* then the container clears the file after reading. To supply the dynamic
OTP, simply do this outside the container:

```bash
echo OTP_HERE > ./vpntoken
```

### Start using `docker`

When using plain docker to run the container it is 
It is mandatory to specify a couple of configuration files respectively volumes
when using plain docker to run the container.

```bash
docker run -d \
--cap-add=NET_ADMIN \
--name=openconnect \
--privileged=true \
--restart=always \
-v "$(pwd)"/authorized_keys:/home/vpn/.ssh/authorized_keys \
-v "$(pwd)"/vpn.config:/vpn/vpn.config:ro \
-v "$(pwd)"/vpnpasswd:/vpn/passwd:ro \
-v "$(pwd)"/vpntoken:/vpn/token \
-p 3128:22 \
oehrlis/openconnect:latest
```

### Start using `docker-compose`

A `docker-compose.yml` file is provided to simplify the start of the container.

```bash
docker-compose up -d
```

Check the logfile to see if OpenConnect starts successfully.

```bash
docker-compose logs -f
```

## Using the VPN

The Docker images *oehrlis/openconnect* currently just does provide a sshd access,
which can be used to forward any connection using ssh port forwarding. Access
can either be done using password or key based ssh login.

Get the created password for the *vpn* user from the container logfile:

```bash
docker-compose logs |grep "vpn password :"
```

Create an ssh session to the Docker container:

```bash
. .env
ssh -N vpn@localhost -p ${SSH_PORT}
```

Forward rdp traffic for some IP:

```bash
. .env
ssh -L 3390:192.168.1.10:3389 -N vpn@localhost -p ${SSH_PORT}
```

## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

- [Existing issues](https://github.com/oehrlis/openconnect/issues)
- [submit new issue](https://github.com/oehrlis/openconnect/issues/new)
