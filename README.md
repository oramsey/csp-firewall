# CSP-Firewall

Simple overview of use/purpose.

## Description

An in-depth paragraph about your project and overview of use.

## Getting Started

### Dependencies
```bash
sudo apt update
```
```bash                                                                                                                                
sudo apt install -y gcc make cmake python3 pkg-config libzmq3-dev libsqlite3-dev libcunit1-dev
```
```bash
sudo apt install -y docker.io docker-compose
```

### Installing

```bash
git clone git@github.com:oramsey/csp-firewall.git
```
```bash
cd csp-firewall
```
```bash
git submodule update --init --recursive
```
### Test commands

```
1. Live Firewall Policy Tests                                                                                                                
                                                                                                                                                   
  These scripts verify the active firewall rule enforcement on a live running container cluster:                                                   
                                                                                                                                                   
    ./tests/node_test_live.sh      # Validates benign vs malicious node authorization                                                              
    ./tests/port_test_live.sh      # Validates allowed vs restricted ports                                                                         
    ./tests/priority_test_live.sh  # Validates prioritized packet restrictions                                                                     
    ./tests/route_test_live.sh     # Validates route injection enforcement                                                                         
    ./tests/payload_test_live.sh   # Validates payload policy                                                                
    ./tests/flood_test_live.sh     # Validates rate-limiting/anti-flooding rules
    ./mission_policy_test/test_mission_policy.sh
```

```
2. Defensive Service Attack Tests                                                                                                            
                                                                                                                                                   
  These test scripts demonstrate that standard CSP administration services (which could leak system metrics or trigger reboots) are successfully   
  blocked when the firewall is active:                                                                                                             
                                                                                                                                                   
    ./tests/service_attack_ident.sh    # Ident request blocks (Port 0)                                                                             
    ./tests/service_attack_ifstats.sh  # Interface statistics blocks (Port 0)                                                                      
    ./tests/service_attack_peek.sh     # Memory peek blocks (Port 0)                                                                               
    ./tests/service_attack_poke.sh     # Memory poke blocks (Port 0)                                                                               
    ./tests/service_attack_clock.sh    # Clock synchronization blocks (Port 0)                                                                     
    ./tests/service_attack_ps.sh       # Process list requests blocks (Port 2)                                                                     
    ./tests/service_attack_mem.sh      # Free memory diagnostics blocks (Port 3)                                                                   
    ./tests/service_attack_reboot.sh   # Satellite reset commands blocks (Port 4)                                                                  
    ./tests/service_attack_buf.sh      # Buffer free statistics blocks (Port 5)                                                                    
    ./tests/service_attack_uptime.sh   # System uptime retrieval blocks (Port 6)                                                                
```

```
 3. Offensive Exploits                                                                                                                        
  
  These scripts execute simulated attacker exploits from the malicious node:
  
    ./exploits/exploit_ident.sh         # Reconnaissance: Profiling system properties
    ./exploits/exploit_ifstats.sh       # Reconnaissance: Profiling interface stats
    ./exploits/exploit_peek.sh          # RCE: Crashing flight software via Null Pointer Peek
    ./exploits/exploit_poke.sh          # RCE: Tampering memory via Null Pointer Poke
    ./exploits/exploit_clock.sh         # Hijack: Ingesting fake time to bypass scheduling
    ./exploits/exploit_ps.sh            # Reconnaissance: Pulling CPU processes list
    ./exploits/exploit_mem.sh           # Reconnaissance: Pulling free heap capacity
    ./exploits/exploit_reboot.sh        # DoS: Sending a hard reboot to sat software
    ./exploits/exploit_buf.sh           # Reconnaissance: Inspecting network buffer pools
    ./exploits/exploit_uptime.sh        # Reconnaissance: Inspecting sat uptime log
    ./exploits/exploit_route_poison.sh  # Hijack: Ingesting rogue routing table parameters
```

```
 4. Firewall Performance & Latency Overhead Test
  
  Measures processing overhead and compares latency (in ms and microseconds) with and without the firewall enabled:
  
    python3 tests/ping_overhead_test.py
```

### Executing program

* Make sure you have everything installed
* Go to the directory
```
cd csp-firewall
```
* Make sure the firewall is on
```
cat docker/firewall/policy_ON.yaml > docker/firewall/policy.yaml
```
* Run the manage.sh script to run the docker compose
```
./manage.sh
```
* Then open another terminal and go back to the same directory
* And run any test besides an exploit test
```
cd csp-firewall
./tests/<yourtest.sh>
```
* You can also attach one of the nodes and manually run commands through their sucahi fs ui
```
sudo docker attach ground-node-a
sudo docker attach malicious-node
sudo docker attach sat-hub-b
```
* To use the test exploits before you run manage.sh turn off the firewall
* Then run whichever exploit you want
```
cat docker/firewall/policy_OFF.yaml > docker/firewall/policy.yaml
./manage.sh

***in a new terminal now***
./exploits/<yourexploit.sh>
```
#### video examples
[![Demonstration of running the CSP firewall](https://img.youtube.com/vi/R0oYROGg4cs/0.jpg)](https://www.youtube.com/watch?v=R0oYROGg4cs)



## Authors

Owen Ramsey, 
Efren Lopez Morales,
Carlos González


## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details

## Acknowledgments
