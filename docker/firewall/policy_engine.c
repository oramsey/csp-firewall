#include "policy_engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Port Definitions from flight software config
#define PORT_FILE   9
#define PORT_TC     10
#define PORT_RPT    11
#define PORT_CMD    12
#define PORT_DBG    13
#define PORT_DIAG   14

bool is_allowed(csp_header_t *header, const uint8_t *payload, size_t payload_len) {
    if (!header->valid) {
        printf("  [Policy] REJECTED: Invalid CSP Header\n");
        return false;
    }

    // --- NODE-LEVEL POLICY ---
    const char* node_policy_env = getenv("NODE_POLICY_ENABLED");
    if (node_policy_env != NULL && strcmp(node_policy_env, "1") == 0) {
        if (header->dst_node == 1 && header->src_node != 10) {
            printf("  [Policy] REJECTED: Node %d is not authorized to talk to Node 1\n", header->src_node);
            return false;
        }
    }

    // --- PORT-LEVEL POLICY ---
    const char* port_policy_env = getenv("PORT_POLICY_ENABLED");
    if (port_policy_env != NULL && strcmp(port_policy_env, "1") == 0) {
        if (header->dst_node == 1) {
            if (header->dst_port == PORT_DBG || header->dst_port == PORT_DIAG) {
                printf("  [Policy] REJECTED: Access to Debug/Diag ports (Port %d) is blocked from external nodes\n", header->dst_port);
                return false;
            }

            if (header->dst_port == PORT_TC || header->dst_port == PORT_FILE || 
                header->dst_port == PORT_RPT || header->dst_port == PORT_CMD) {
                if (header->src_node != 10) {
                    printf("  [Policy] REJECTED: Node %d unauthorized for functional port %d\n", header->src_node, header->dst_port);
                    return false;
                }
            }
        }
    }

    // --- PAYLOAD-LEVEL POLICY (Deep Packet Inspection) ---
    const char* payload_policy_env = getenv("PAYLOAD_POLICY_ENABLED");
    if (payload_policy_env != NULL && strcmp(payload_policy_env, "1") == 0) {
        // Only inspect payloads going to command ports (10 or 12)
        if (header->dst_node == 1 && (header->dst_port == PORT_TC || header->dst_port == PORT_CMD)) {
            if (payload != NULL && payload_len > 0) {
                // Denylist of high-risk commands
                const char* denylist[] = {
                    "obc_system", // Can execute shell commands
                    "obc_reset",  // Reboots the system
                    "obc_exit",   // Shuts down the software
                    "obc_rm",     // Deletes files
                    "obc_mkdir"   // Modifies directory structure
                };
                int num_rules = sizeof(denylist) / sizeof(denylist[0]);

                for (int i = 0; i < num_rules; i++) {
                    // Check if the denied string exists anywhere in the payload
                    if (strstr((const char*)payload, denylist[i]) != NULL) {
                        printf("  [Policy] REJECTED: High-risk command '%s' detected in payload!\n", denylist[i]);
                        return false;
                    }
                }
            }
        }
    }

    return true;
}
