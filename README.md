# sonic-lab
# sonic-lab: SONiC networking labs (VLAN, inter-VLAN routing, eBGP) with automated checks

Hands-on labs built on **SONiC-VS** (the virtual SONiC switch) using **Containerlab** in a GitHub Codespace, so no physical devices are needed.
Each lab has a topology file, the commands used, expected results, and a break-and-fix test that proves the feature works.

| Lab | Topic | Files |
|---|---|---|
| 1 | Static route between 2 switches | `lab1-static.clab.yml`, `RESULTS-lab1.md` |
| 2 | VLAN and trunk across 2 switches | `lab2-vlan.clab.yml`, `RESULTS-lab2-vlan.md` |
| 3 | Inter-VLAN routing (SVI gateways) | `lab3-intervlan.clab.yml`, `RESULTS-lab3-intervlan.md` |
| 4 | eBGP on 3 switches, link failure and recovery | `lab4-dynamic.clab.yml`, `lab4-setup.sh`, `RESULTS-lab4-bgp.md` |
| 5 | Automated checks for Lab 4 (pytest) | `test_lab4.py` |

## Requirements
- A GitHub Codespace (Docker is already installed)
- Containerlab: `bash -c "$(curl -sL https://get.containerlab.dev)"`
- The SONiC-VS Docker image (`docker-sonic-vs`). It is about 900 MB, so it is **not** in this repo (see `.gitignore`). Load it once with:
```
  gunzip docker-sonic-vs.gz
  docker load -i docker-sonic-vs
```
- Python and pytest for Lab 5: `pip install pytest`

## How to run any lab
```
sudo containerlab deploy -t <lab file>.clab.yml     # build the lab
docker ps                                            # note the container names
docker exec -it <container name> bash                # enter a switch (type exit to leave)
sudo containerlab destroy -t <lab file>.clab.yml     # remove the lab
```
Container names look like `clab-<lab name>-sw1`. Inside a switch, use `show ...` and `config ...`. For routing details, use `vtysh -c "show ip route"`.

**Note:** SONiC-VS forgets its configuration if the Codespace sleeps or the containers restart. Re-deploy and re-apply the commands (Lab 4 has a script for this).

---

## Lab 1: Static route
**Goal:** sw1 reaches sw2's loopback (10.0.0.1) through a static route.

```
sw1 Ethernet0 (10.1.1.1/24) ---- Ethernet0 sw2 (10.1.1.2/24)
                                 sw2 Loopback0 = 10.0.0.1/32
```

**sw1:**
```
config interface ip add Ethernet0 10.1.1.1/24
config interface startup Ethernet0
config route add prefix 10.0.0.0/24 nexthop 10.1.1.2
```
**sw2:**
```
config interface ip add Ethernet0 10.1.1.2/24
config interface startup Ethernet0
config loopback add Loopback0
config interface ip add Loopback0 10.0.0.1/32
```
**Verify (on sw1):** `vtysh -c "show ip route"` shows `S>* 10.0.0.0/24 via 10.1.1.2`, and `ping 10.0.0.1` works.
**Break and fix:** `config route del prefix 10.0.0.0/24 nexthop 10.1.1.2` makes the ping fail (100% loss). Adding the route back fixes it.

---

## Lab 2: VLAN and trunk
**Goal:** h1 and h2 are in VLAN 10 on different switches and talk across a tagged trunk.

```
h1 --(untagged, VLAN 10)-- sw1 ==(trunk, tagged)== sw2 --(untagged, VLAN 10)-- h2
10.10.10.1                                                                    10.10.10.2
```
Ports: `Ethernet0` is the trunk between switches, `Ethernet4` is the host port.

**On sw1 and sw2 (same commands):**
```
config vlan add 10
config vlan member add 10 Ethernet0
config vlan member add -u 10 Ethernet4
config interface startup Ethernet0
config interface startup Ethernet4
```
**Verify:** `show vlan brief` shows Ethernet0 tagged and Ethernet4 untagged. `ping 10.10.10.2` from h1 works.
**Break and fix:** `config vlan member del 10 Ethernet0` on sw1 makes the ping fail. Adding it back fixes it.

---

## Lab 3: Inter-VLAN routing
**Goal:** h1 (VLAN 10) reaches h2 (VLAN 20) through sw1 acting as a router.

```
h1 (10.10.10.1, gw 10.10.10.254) --- sw1 (Vlan10 .254 | Vlan20 .254) --- h2 (10.20.20.1, gw 10.20.20.254)
```

**sw1:**
```
config vlan add 10
config vlan add 20
config vlan member add -u 10 Ethernet0
config vlan member add -u 20 Ethernet4
config interface startup Ethernet0
config interface startup Ethernet4
config interface ip add Vlan10 10.10.10.254/24
config interface ip add Vlan20 10.20.20.254/24
```
Each host uses its VLAN gateway as the default route (`default via 10.10.10.254` / `10.20.20.254`), set in the topology file.

**Verify:** `ping 10.20.20.1` from h1 works with **ttl=63** (one router hop), and `traceroute 10.20.20.1` shows `10.10.10.254` as hop 1.
**Break and fix:** `config interface ip remove Vlan20 10.20.20.254/24` makes the ping fail. Adding it back fixes it.

---

## Lab 4: eBGP on 3 switches
**Goal:** sw1 learns sw3's loopback through BGP, with no static routes.

```
sw1 ---- 10.1.12.0/24 ---- sw2 ---- 10.1.23.0/24 ---- sw3
AS 65001                   AS 65002                   AS 65003
1.1.1.1/32                 2.2.2.2/32                 3.3.3.3/32
```

**Run:**
```
sudo containerlab deploy -t lab4-dynamic.clab.yml
bash lab4-setup.sh
```
`lab4-setup.sh` sets the interface IPs, the loopbacks and the BGP config on all three switches. It sets BGP timers to 3 s keepalive and 9 s hold. (`Loopback0 already exists` messages on a re-run are harmless.)

**Verify:**
```
docker exec clab-lab4-dynamic-sw2 vtysh -c "show bgp summary"     # both neighbors show a number in State/PfxRcd
docker exec clab-lab4-dynamic-sw1 vtysh -c "show ip route"        # B>* routes for 2.2.2.2 and 3.3.3.3 via 10.1.12.2
docker exec clab-lab4-dynamic-sw1 ping -c 2 3.3.3.3
```
**Break and fix:** shut sw3's link with `config interface shutdown Ethernet0` (on sw3). The BGP session drops, the `3.3.3.3` route disappears from sw1 on its own, and the ping fails. `config interface startup Ethernet0` restores everything without touching sw1.

### Findings
- **Default BGP timers blackhole traffic.** With the default 180 s hold time, sw1 kept a route to a dead path and the ping failed with `Host Unreachable`. Timers of 3/9 cut the detection time to seconds.
- **Ping works without `-I`.** SONiC sets the source to the loopback on BGP routes (`rmapsrc 1.1.1.1`), so sw3 can reply.
- **A default route can hide a failure.** Once the BGP route was withdrawn, the ping showed silent loss instead of `unreachable`, because the management default route caught it.

---

## Lab 5: Automated checks (pytest)
`test_lab4.py` runs 4 checks against the running Lab 4:
1. sw2 has both BGP neighbors established
2. sw1 learns the loopbacks of sw2 and sw3 through BGP
3. sw1 can ping sw3's loopback
4. Link failure removes the route, and recovery restores it (with a check that the route exists before the test starts)

```
pytest -v test_lab4.py     # 4 passed in about 20 seconds
```
**Proof that the tests can fail:** removing a neighbor (`no neighbor 10.1.23.3` in `router bgp 65002` on sw2) makes tests 1 to 3 fail with clear messages. Restoring the neighbor makes all 4 pass.

Note: test 4 shuts and restores sw3's `Ethernet0`, so each run resets that BGP session.

---

## Limitations
- SONiC-VS is a virtual switch, so there is no real ASIC forwarding, and results for hardware features can differ.
- Labs 1 to 3 are configured by hand (commands above). Only Lab 4 has a setup script.
- Lab 5 covers Lab 4 only.