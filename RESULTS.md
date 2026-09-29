# Lab 1: Static route on SONiC-VS

| Test | Expected | Actual | Result |
|---|---|---|---|
| Ping sw1 to sw2 (10.1.1.2) | Reply | Reply, 0% loss | Pass |
| Ping sw1 to 10.0.0.1 with static route | Reply | Reply, 0% loss | Pass |
| Ping 10.0.0.1 after removing route | No reply | 100% packet loss | Pass |
| Ping 10.0.0.1 after adding route back | Reply | Reply, 0% loss | Pass |