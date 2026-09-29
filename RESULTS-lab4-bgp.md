# Lab 4: eBGP between 3 SONiC-VS switches

| Test | Expected | Actual | Result |
|---|---|---|---|
| Ping sw1 to 3.3.3.3 before BGP | Fail (no route) | 100% packet loss | Pass |
| show bgp summary on sw2 | 2 neighbors established | Both up, 1 prefix each | Pass |
| sw1 route table | B routes for 2.2.2.2 and 3.3.3.3 via 10.1.12.2 | Matches | Pass |
| Ping sw1 to 3.3.3.3 after BGP | Reply | 0% loss, ttl=63 | Pass |
| Shut sw3 Ethernet0 (default 180s hold timer) | Route removed quickly | Route stayed, ping failed (Host Unreachable) | Finding |
| Shut sw3 Ethernet0 (timers 3 9) | Route removed within ~10s | sw3 neighbor in Connect, 3.3.3.3 route gone from sw1, ping 100% loss | Pass |
| Bring sw3 Ethernet0 back | Route returns, ping works | Neighbor re-established, B route back, 0% loss | Pass |

Findings:
- With default timers, BGP kept a stale route for up to 180 seconds after the link failed, so traffic was blackholed. Timers 3/9 shorten this.
- After the route was withdrawn, the ping showed silent loss (not "unreachable") because of the default route via the management port.
- SONiC sets the source address to the loopback (rmapsrc) on BGP routes, so ping works without -I.