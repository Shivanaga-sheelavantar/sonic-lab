# Lab 3: Inter-VLAN routing on SONiC-VS

| Test | Expected | Actual | Result |
|---|---|---|---|
| show vlan brief | VLAN 10 on Ethernet0, VLAN 20 on Ethernet4, gateways .254 | Matches | Pass |
| Ping h1 to gateway 10.10.10.254 | Reply | Reply, 0% loss | Pass |
| Ping h1 (VLAN 10) to h2 (VLAN 20) | Reply via router | Reply, 0% loss, ttl=63 | Pass |
| Traceroute h1 to h2 | Hop 1 is 10.10.10.254 | Hop 1 is 10.10.10.254, hop 2 is 10.20.20.1 | Pass |
| Ping h1 to h2 after removing Vlan20 gateway | No reply | 100% packet loss | Pass |
| Ping h1 to h2 after adding gateway back | Reply | Reply, 0% loss, ttl=63 | Pass |