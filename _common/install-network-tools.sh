#!/usr/bin/env bash
# The netshoot replacement: everything k8s-shell used to get "for free" by
# building FROM nicolaka/netshoot, now installed explicitly via apt. Tools
# with no reliable apt package (ctop, calicoctl, termshark, grpcurl, fortio,
# trippy, websocat) come from fetch-binaries.sh instead, not from here.
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$COMMON_DIR/lib.sh"

apt_refresh

# tshark's postinst asks (via debconf) whether non-root users should be able
# to capture packets (installs dumpcap setuid root:wireshark). Answering it
# up front avoids an interactive prompt hanging an unattended apt install.
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

apt_install \
  apache2-utils \
  bind9-dnsutils \
  bird2 \
  bridge-utils \
  conntrack \
  ethtool \
  file \
  fping \
  httpie \
  iftop \
  iperf \
  iperf3 \
  iproute2 \
  ipset \
  iptables \
  iptraf-ng \
  iputils-arping \
  iputils-ping \
  iputils-tracepath \
  ipvsadm \
  ldnsutils \
  mtr-tiny \
  netcat-openbsd \
  nftables \
  ngrep \
  nmap \
  openssh-client \
  openssl \
  oping \
  python3-pip \
  python3-scapy \
  python3-setuptools \
  snmp \
  socat \
  speedtest-cli \
  strace \
  swaks \
  tcpdump \
  tcptraceroute \
  tshark \
  util-linux

# Defensive re-assertion of dumpcap's non-root-capture permissions: the
# debconf answer above should already have the tshark package's postinst set
# this, but pin it explicitly so it doesn't silently regress on a future
# Ubuntu tshark package change. Raw-socket tools (tcpdump, nmap SYN scans)
# still need CAP_NET_RAW/root at the container's securityContext level - this
# only covers tshark/dumpcap's own capture-group mechanism.
chgrp wireshark /usr/bin/dumpcap
chmod 4750 /usr/bin/dumpcap

apt_cleanup
