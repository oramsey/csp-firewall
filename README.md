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

* How to run the program
* Step-by-step bullets
```
code blocks for commands
```

## Help

Any advise for common problems or issues.
```
command to run if program contains helper info
```

## Authors

Owen Ramsey 
Efren Lopez Morales
Carlos González
## Version History

* 0.2
    * Various bug fixes and optimizations
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release

## License

This project is licensed under the [NAME HERE] License - see the LICENSE.md file for details

## Acknowledgments
