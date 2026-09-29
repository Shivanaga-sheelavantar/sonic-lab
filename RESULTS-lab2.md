# Lab 2: VLAN 10 across a trunk on SONiC-VS

| Test | Expected | Actual | Result |
|---|---|---|---|
| show vlan brief on sw1 and sw2 | VLAN 10: Ethernet0 tagged, Ethernet4 untagged | Matches | Pass |
| Ping h1 to h2 (10.10.10.2) with trunk in VLAN 10 | Reply | Reply, 0% loss | Pass |
| Ping h1 to h2 after removing trunk from VLAN 10 on sw1 | No reply | 100% packet loss | Pass |
| Ping h1 to h2 after adding trunk back | Reply | Reply, 0% loss | Pass |