#!/bin/bash
for n in 1 2 3; do
  docker exec clab-lab5-stp-sw$n ip link add name br0 type bridge stp_state 1
  docker exec clab-lab5-stp-sw$n ip link set eth1 master br0
  docker exec clab-lab5-stp-sw$n ip link set eth2 master br0
  docker exec clab-lab5-stp-sw$n ip link set eth1 up
  docker exec clab-lab5-stp-sw$n ip link set eth2 up
  docker exec clab-lab5-stp-sw$n ip link set br0 up
done
