#!/usr/bin/env bash
set -euo pipefail

if ! grep -q '^PasswordAuthentication no' /etc/ssh/sshd_config; then
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
fi
if ! grep -q '^PermitRootLogin no' /etc/ssh/sshd_config; then
  sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
fi

systemctl restart ssh || systemctl restart sshd

apt-get update
apt-get install -y --no-install-recommends ufw

ufw default deny incoming
ufw default allow outgoing
ufw default allow routed
ufw allow OpenSSH
ufw --force enable

if grep -q '^DEFAULT_FORWARD_POLICY=' /etc/default/ufw; then
  sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
else
  echo 'DEFAULT_FORWARD_POLICY="ACCEPT"' >>/etc/default/ufw
fi

ufw reload

sysctl -w net.ipv4.ip_forward=1
if grep -q '^net.ipv4.ip_forward=' /etc/sysctl.conf; then
  sed -i 's/^net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
else
  echo 'net.ipv4.ip_forward=1' >>/etc/sysctl.conf
fi
