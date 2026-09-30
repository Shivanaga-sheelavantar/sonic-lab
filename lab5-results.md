# Lab 5: STP on a 3-switch triangle (Linux bridges in SONiC-VS)

| Test | Expected | Actual | Result |
|---|---|---|---|
| Check for STP in SONiC-VS | STP daemon running | config spanning-tree exists, but no STP process in supervisorctl | Finding |
| Turn on STP with Linux bridges (br0, stp_state 1) | One port blocked | Only sw1 eth1 blocking, all others forwarding | Pass |
| Root bridge election | Lowest bridge ID (same priority, lowest MAC) | sw3 has lowest MAC, both its ports forwarding | Pass |
| Shut sw3 eth2 | Blocked port takes over | sw1 eth1 blocking to forwarding, eth2 disabled | Pass |
| Bring sw3 eth2 back | Original state returns | sw1 eth1 back to blocking, eth2 relearning | Pass |

Findings:
- The SONiC-VS image has the spanning-tree command but no STP daemon, so STP was tested with Linux bridges.
- STP cuts a loop by blocking one port, and unblocks it when an active link fails.