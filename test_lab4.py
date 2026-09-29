import subprocess
import time

LAB = "clab-lab4-dynamic"


def run(node, command):
    """Run a command inside one switch. Returns (exit_code, output)."""
    result = subprocess.run(
        f"docker exec {LAB}-{node} {command}",
        shell=True, capture_output=True, text=True,
    )
    return result.returncode, result.stdout + result.stderr


def bgp_neighbor_up(node, neighbor_ip):
    """True if the neighbor shows a number in the State/PfxRcd column."""
    _, out = run(node, 'vtysh -c "show bgp summary"')
    for line in out.splitlines():
        if line.startswith(neighbor_ip):
            return line.split()[9].isdigit()
    return False


def has_bgp_route(node, prefix):
    """True if the switch has a BGP (B) route for this prefix."""
    _, out = run(node, 'vtysh -c "show ip route"')
    return any(line.startswith("B") and prefix in line for line in out.splitlines())


def wait_until(condition, timeout, interval=3):
    """Check condition() every few seconds until it is True or time runs out."""
    end = time.time() + timeout
    while time.time() < end:
        if condition():
            return True
        time.sleep(interval)
    return condition()


def test_sw2_has_two_bgp_neighbors_up():
    assert bgp_neighbor_up("sw2", "10.1.12.1"), "sw2 to sw1 is not up"
    assert bgp_neighbor_up("sw2", "10.1.23.3"), "sw2 to sw3 is not up"


def test_sw1_learns_loopbacks_through_bgp():
    assert has_bgp_route("sw1", "2.2.2.2/32")
    assert has_bgp_route("sw1", "3.3.3.3/32")


def test_sw1_can_ping_sw3_loopback():
    code, out = run("sw1", "ping -c 2 -W 2 3.3.3.3")
    assert code == 0, out


def test_link_failure_removes_route_and_recovery_restores_it():
    try:
        run("sw3", "config interface shutdown Ethernet0")
        gone = wait_until(lambda: not has_bgp_route("sw1", "3.3.3.3/32"), timeout=30)
        assert gone, "route to 3.3.3.3 was still on sw1 30s after the link failed"
        code, _ = run("sw1", "ping -c 2 -W 2 3.3.3.3")
        assert code != 0, "ping should fail while the link is down"
    finally:
        run("sw3", "config interface startup Ethernet0")
    back = wait_until(lambda: has_bgp_route("sw1", "3.3.3.3/32"), timeout=150)
    assert back, "route to 3.3.3.3 did not come back within 150s"
    code, out = run("sw1", "ping -c 2 -W 2 3.3.3.3")
    assert code == 0, out