#!/bin/bash
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10000:20000 -j REDIRECT --to-ports 8443
ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport 10000:20000 -j REDIRECT --to-ports 8443
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 21000:29000 -j REDIRECT --to-ports 8444
ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport 21000:29000 -j REDIRECT --to-ports 8444
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 21000:29000 -j REDIRECT --to-ports 8445
ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport 21000:29000 -j REDIRECT --to-ports 8445
