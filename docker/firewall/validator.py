import yaml
import json
import sys
import os
from jsonschema import validate, ValidationError

def generate_c_data(artifact):
    """
    Translates the validated YAML into C-style arrays for the policy engine.
    """
    with open("policy_data.h", "w") as f:
        f.write("/* AUTO-GENERATED POLICY DATA - DO NOT EDIT */\n")
        f.write("#ifndef POLICY_DATA_H\n#define POLICY_DATA_H\n\n")
        
        # 1. Default Action & Firewall Settings
        default_drop = 1 if artifact['firewall']['default_action'] == 'drop' else 0
        f.write(f"#define POLICY_DEFAULT_DROP {default_drop}\n")

        rate_limit = artifact['firewall'].get('rate_limit', 0)
        rate_window = artifact['firewall'].get('rate_window', 60)
        f.write(f"#define POLICY_RATE_LIMIT {rate_limit}\n")
        f.write(f"#define POLICY_RATE_WINDOW {rate_window}\n")

        # Convert allowed priorities into a bitmask (e.g., [2, 3] -> (1<<2) | (1<<3) = 12)
        priorities = artifact['firewall'].get('allowed_priorities', [0, 1, 2, 3])
        prio_mask = sum(1 << p for p in priorities)
        f.write(f"#define POLICY_PRIO_MASK {prio_mask}\n\n")

        # 2. Node Mappings
        node_map = {}
        for cat in ['ground', 'space']:
            for node in artifact['nodes'].get(cat, []):
                node_map[node['name']] = node['id']
                f.write(f"#define ID_{node['name'].upper()} {node['id']}\n")
        
        # 3. Port Rules
        f.write("\ntypedef struct {\n    uint8_t src, dst, dport, action, dir;\n} c_rule_t;\n")
        f.write("#define ACTION_ALLOW 1\n#define ACTION_DROP 0\n")
        f.write("#define DIR_G2S 1\n#define DIR_S2G 2\n\n")
        
        f.write(f"#define NUM_RULES {len(artifact['rules'])}\n")
        f.write("static const c_rule_t rules[NUM_RULES] = {\n")
        for r in artifact['rules']:
            src = node_map.get(r['src'], 255) if r['src'] != 'any' else 255
            dst = node_map.get(r['dst'], 255) if r['dst'] != 'any' else 255
            dport = r.get('dport', 255)
            action = 1 if r['action'] == 'allow' else 0
            direction = 1 if r['direction'] == 'ground_to_space' else 2
            f.write(f"    {{ {src}, {dst}, {dport}, {action}, {direction} }}, // {r['name']}\n")
        f.write("};\n\n")

        # 4. Command DPI Rules
        f.write("typedef struct {\n    uint8_t dport, offset, len, allowed_src;\n    uint8_t match[16];\n} c_command_t;\n")
        f.write(f"#define NUM_CMDS {len(artifact['commands'])}\n")
        f.write("static const c_command_t cmd_rules[NUM_CMDS] = {\n")
        for c in artifact['commands']:
            val = bytes.fromhex(c['match']['value_hex'])
            val_str = ", ".join([hex(b) for b in val])
            
            # Map the allowed source name to its ID
            allowed_src_name = c.get('allowed_sources', ['any'])[0]
            if allowed_src_name == 'none':
                allowed_src = 254 # 254 means nobody is allowed
            else:
                allowed_src = node_map.get(allowed_src_name, 255) if allowed_src_name != 'any' else 255
            
            f.write(f"    {{ {c['dport']}, {c['match']['offset']}, {len(val)}, {allowed_src}, {{ {val_str} }} }}, // {c['name']}\n")
        f.write("};\n\n")

        f.write("#endif\n")

def main():
    yaml_file = "policy.yaml"
    json_schema_file = "policy_schema.json"

    if not os.path.exists(yaml_file):
        print(f"Error: {yaml_file} not found")
        sys.exit(1)

    with open(yaml_file, 'r') as f:
        artifact = yaml.safe_load(f)

    with open(json_schema_file, 'r') as f:
        schema = json.load(f)

    try:
        validate(instance=artifact, schema=schema)
        print(f"SUCCESS: {yaml_file} is VALID.")
        generate_c_data(artifact)
        print("SUCCESS: C policy data generated.")
    except ValidationError as e:
        print(f"CRITICAL ERROR: {yaml_file} is INVALID!")
        print(f"Path: {'.'.join(str(v) for v in e.path)}")
        print(f"Message: {e.message}")
        sys.exit(1)

if __name__ == "__main__":
    main()
