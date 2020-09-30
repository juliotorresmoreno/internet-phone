#!/bin/bash

if [ $USER != "root" ]; then
  echo "no eres root"
  exit 1
fi

clear() {
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -t nat -F
  iptables -t mangle -F
  iptables -F
  iptables -X
}

redirect() {
  iptables -t nat -N REDSOCKS

  # Ignore LANs and some other reserved addresses.
  # See http://en.wikipedia.org/wiki/Reserved_IP_addresses#Reserved_IPv4_addresses
  # and http://tools.ietf.org/html/rfc5735 for full list of reserved networks.
  iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 100.64.0.0/10 -j RETURN
  iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
  iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
  iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
  iptables -t nat -A REDSOCKS -d 198.18.0.0/15 -j RETURN
  iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
  iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

  # Anything else should be redirected to port 12345
  iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345

  iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

  #ip rule add fwmark 0x01/0x01 table 100
  #ip route add local 0.0.0.0/0 dev lo table 100
  #iptables -t mangle -N REDSOCKS2
  #iptables -t mangle -A REDSOCKS2 -p udp -j TPROXY --on-port 10053 --tproxy-mark 0x01/0x01
  #iptables -t mangle -A PREROUTING -j REDSOCKS2
}

stop() {
  clear
  killall redsocks
  echo "conexión detenida"
}

start() {
  stop
  redirect
  redsocks -c /etc/redsocks.conf
  echo "conexión establecida"
  ping -c 1 www.google.com | grep icmp_seq
  echo 
}

if [[ $1 = "start" ]]; then
  start
  exit 0
fi

if [[ $1 = "stop" ]]; then
  stop
  exit 0
fi

echo "El comando no esta soportado"
