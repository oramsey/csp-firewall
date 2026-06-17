#!/usr/bin/env python3
import subprocess
import re
import sys
import statistics
import time

def run_bench():
    print("Connecting to ground-node-a suchai-app...")
    sys.stdout.flush()
    
    # Start suchai-app via docker exec
    proc = subprocess.Popen(
        ["docker", "exec", "-i", "ground-node-a", "/suchai/build/apps/simple/suchai-app"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1
    )
    
    rtts_internal = []
    rtts_external = []
    
    # Compile regex to match RTT output from suchai-app: Ping to <node> took <rtt>
    ping_re = re.compile(r"Ping to \d+ took (-?\d+)")
    
    # Let's perform a few warm-up pings first
    for _ in range(5):
        proc.stdin.write("com_ping 1\n")
        proc.stdin.flush()
        while True:
            line = proc.stdout.readline()
            if not line:
                break
            if "Ping to" in line:
                break
                
    print("Warm-up complete. Starting benchmark of 1000 pings...")
    sys.stdout.flush()
    
    t_start_all = time.time()
    
    for i in range(1000):
        t_start_us = time.perf_counter_ns()
        proc.stdin.write("com_ping 1\n")
        proc.stdin.flush()
        
        # Read stdout line by line until we find the ping response
        found = False
        while True:
            line = proc.stdout.readline()
            if not line:
                break
            match = ping_re.search(line)
            if match:
                t_end_us = time.perf_counter_ns()
                rtt_internal = int(match.group(1))
                if rtt_internal >= 0:
                    rtts_internal.append(rtt_internal)
                    rtts_external.append((t_end_us - t_start_us) / 1000.0)
                found = True
                break
                
        if not found:
            print(f"Ping {i+1} timed out or failed to parse!")
            sys.stdout.flush()
            
        if (i + 1) % 100 == 0:
            print(f"Completed {i + 1}/1000 pings...")
            sys.stdout.flush()
            
    t_duration = time.time() - t_start_all
    
    # Terminate the process cleanly
    proc.stdin.write("obc_exit\n")
    proc.stdin.flush()
    try:
        proc.wait(timeout=2)
    except subprocess.TimeoutExpired:
        proc.kill()
        
    print("\n" + "="*50)
    print("BENCHMARK SUMMARY")
    print("="*50)
    print(f"Total duration: {t_duration:.2f} seconds")
    print(f"Sent: 1000, Received: {len(rtts_internal)}, Loss: {100.0 * (1000 - len(rtts_internal)) / 1000.0:.1f}%")
    
    if len(rtts_internal) > 0:
        print("\n1. Internal CSP Stack RTT (reported by suchai-app in ms):")
        print(f"   Min   : {min(rtts_internal)} ms")
        print(f"   Max   : {max(rtts_internal)} ms")
        print(f"   Mean  : {statistics.mean(rtts_internal):.2f} ms")
        print(f"   Median: {statistics.median(rtts_internal):.2f} ms")
        
        print("\n2. External Process-to-Process RTT (measured by Python in us):")
        print(f"   Min   : {min(rtts_external):.2f} us")
        print(f"   Max   : {max(rtts_external):.2f} us")
        print(f"   Mean  : {statistics.mean(rtts_external):.2f} us")
        print(f"   Median: {statistics.median(rtts_external):.2f} us")
    else:
        print("No successful ping replies received!")
    print("="*50)

if __name__ == "__main__":
    run_bench()
