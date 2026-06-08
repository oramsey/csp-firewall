#include "policy_engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Include the auto-generated rules from the YAML config
#include "policy_data.h"

bool is_allowed(firewall_header_t *header, const uint8_t *payload, size_t payload_len) {
    if (!header) return false;

    // Default action fallback
    bool allowed = (POLICY_DEFAULT_DROP == 0); 
    
    // Determine traffic direction
    uint8_t current_dir = (header->dst_node == ID_SATELLITE_OBC) ? DIR_G2S : DIR_S2G;

    // --- 1. Evaluate Standard Rules (Node & Port Level) ---
    bool matched_rule = false;
    for (int i = 0; i < NUM_RULES; i++) {
        if ((rules[i].src == header->src_node || rules[i].src == 255) &&
            (rules[i].dst == header->dst_node || rules[i].dst == 255) &&
            (rules[i].dport == header->dst_port || rules[i].dport == 255) &&
            (rules[i].dir == current_dir)) {
            
            allowed = (rules[i].action == ACTION_ALLOW);
            matched_rule = true;
            
            if (!allowed) {
                printf("  [Policy] REJECTED by Rule #%d (Port %d blocked)\n", i, header->dst_port);
                fflush(stdout);
                return false;
            }
        }
    }

    if (!matched_rule && POLICY_DEFAULT_DROP) {
        printf("  [Policy] REJECTED by Default Drop Policy\n");
        fflush(stdout);
        return false;
    }

    // --- 2. Evaluate Payload Rules (Deep Packet Inspection) ---
    if (payload != NULL && payload_len > 0) {
        for (int i = 0; i < NUM_CMDS; i++) {
            if (header->dst_port == cmd_rules[i].dport) {
                
                // Check if the payload is long enough to contain the match at the offset
                if (payload_len >= cmd_rules[i].offset + cmd_rules[i].len) {
                    
                    // Compare the bytes
                    if (memcmp(&payload[cmd_rules[i].offset], cmd_rules[i].match, cmd_rules[i].len) == 0) {
                        
                        // Command matched! Check if source is allowed
                        if (header->src_node != cmd_rules[i].allowed_src && cmd_rules[i].allowed_src != 255) {
                            printf("  [Policy] REJECTED: Node %d attempted unauthorized restricted command!\n", header->src_node);
                            fflush(stdout);
                            return false;
                        }
                    }
                }
            }
        }
    }

    return allowed;
}
