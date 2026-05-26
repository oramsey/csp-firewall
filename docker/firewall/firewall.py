import zmq
import sys
import os

def bridge(hub_a_ip, hub_b_ip, hub_a_port_in="8002", hub_a_port_out="8001", hub_b_port_in="8002", hub_b_port_out="8001"):
    context = zmq.Context()

    # Hub A sockets
    # We SUB from Hub A's OUT port (XPUB) to get all traffic on network A
    sub_a = context.socket(zmq.SUB)
    sub_a.connect(f"tcp://{hub_a_ip}:{hub_a_port_out}")
    sub_a.setsockopt(zmq.SUBSCRIBE, b"") 

    # We PUB to Hub A's IN port (XSUB) to send traffic to network A
    pub_a = context.socket(zmq.PUB)
    pub_a.connect(f"tcp://{hub_a_ip}:{hub_a_port_in}")

    # Hub B sockets
    # We SUB from Hub B's OUT port (XPUB) to get all traffic on network B
    sub_b = context.socket(zmq.SUB)
    sub_b.connect(f"tcp://{hub_b_ip}:{hub_b_port_out}")
    sub_b.setsockopt(zmq.SUBSCRIBE, b"") 

    # We PUB to Hub B's IN port (XSUB) to send traffic to network B
    pub_b = context.socket(zmq.PUB)
    pub_b.connect(f"tcp://{hub_b_ip}:{hub_b_port_in}")

    poller = zmq.Poller()
    poller.register(sub_a, zmq.POLLIN)
    poller.register(sub_b, zmq.POLLIN)

    print(f"CSP Firewall Bridge started:")
    print(f"  Network A (Ground): {hub_a_ip}:{hub_a_port_out}/{hub_a_port_in}")
    print(f"  Network B (Space):  {hub_b_ip}:{hub_b_port_out}/{hub_b_port_in}")
    print("  Status: Letting everything through (Placeholder)")

    try:
        while True:
            socks = dict(poller.poll(1000)) # 1s timeout

            if sub_a in socks:
                msg = sub_a.recv_multipart()
                # PLACEHOLDER: No filtering yet. 
                # Inspecting msg[0] would reveal the CSP header.
                pub_b.send_multipart(msg)
                print(f"[A -> B] Forwarded packet: {msg[0][:16].hex()}...")

            if sub_b in socks:
                msg = sub_b.recv_multipart()
                # PLACEHOLDER: No filtering yet.
                pub_a.send_multipart(msg)
                print(f"[B -> A] Forwarded packet: {msg[0][:16].hex()}...")
    except KeyboardInterrupt:
        print("Stopping firewall...")
    finally:
        sub_a.close()
        pub_a.close()
        sub_b.close()
        pub_b.close()
        context.term()

if __name__ == "__main__":
    # Use environment variables or defaults
    HUB_A_IP = os.environ.get("HUB_A_IP", "hub-a")
    HUB_B_IP = os.environ.get("HUB_B_IP", "hub-b")
    
    bridge(HUB_A_IP, HUB_B_IP)
