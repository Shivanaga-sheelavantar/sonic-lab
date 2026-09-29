#!/bin/bash
# Lab 4: 3 SONiC switches, eBGP. Addresses first, then BGP.

docker exec clab-lab4-dynamic-sw1 config interface ip add Ethernet0 10.1.12.1/24
docker exec clab-lab4-dynamic-sw1 config interface startup Ethernet0
docker exec clab-lab4-dynamic-sw1 config loopback add Loopback0
docker exec clab-lab4-dynamic-sw1 config interface ip add Loopback0 1.1.1.1/32

docker exec clab-lab4-dynamic-sw2 config interface ip add Ethernet0 10.1.12.2/24
docker exec clab-lab4-dynamic-sw2 config interface startup Ethernet0
docker exec clab-lab4-dynamic-sw2 config interface ip add Ethernet4 10.1.23.2/24
docker exec clab-lab4-dynamic-sw2 config interface startup Ethernet4
docker exec clab-lab4-dynamic-sw2 config loopback add Loopback0
docker exec clab-lab4-dynamic-sw2 config interface ip add Loopback0 2.2.2.2/32

docker exec clab-lab4-dynamic-sw3 config interface ip add Ethernet0 10.1.23.3/24
docker exec clab-lab4-dynamic-sw3 config interface startup Ethernet0
docker exec clab-lab4-dynamic-sw3 config loopback add Loopback0
docker exec clab-lab4-dynamic-sw3 config interface ip add Loopback0 3.3.3.3/32

docker exec -i clab-lab4-dynamic-sw1 vtysh <<'EOF'
configure terminal
router bgp 65001
 bgp router-id 1.1.1.1
 no bgp ebgp-requires-policy
 timers bgp 3 9
 neighbor 10.1.12.2 remote-as 65002
 address-family ipv4 unicast
  network 1.1.1.1/32
 exit-address-family
end
EOF

docker exec -i clab-lab4-dynamic-sw2 vtysh <<'EOF'
configure terminal
router bgp 65002
 bgp router-id 2.2.2.2
 no bgp ebgp-requires-policy
 timers bgp 3 9
 neighbor 10.1.12.1 remote-as 65001
 neighbor 10.1.23.3 remote-as 65003
 address-family ipv4 unicast
  network 2.2.2.2/32
 exit-address-family
end
EOF

docker exec -i clab-lab4-dynamic-sw3 vtysh <<'EOF'
configure terminal
router bgp 65003
 bgp router-id 3.3.3.3
 no bgp ebgp-requires-policy
 timers bgp 3 9
 neighbor 10.1.23.2 remote-as 65002
 address-family ipv4 unicast
  network 3.3.3.3/32
 exit-address-family
end
EOF