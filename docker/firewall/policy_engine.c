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

bool is_allowed(csp_header_t *header) {
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
        // Only apply these rules to traffic going TO the satellite (Node 1)
        if (header->dst_node == 1) {
            
            // 1. Block Debug and Diagnostic ports entirely from external nodes
            if (header->dst_port == PORT_DBG || header->dst_port == PORT_DIAG) {
                printf("  [Policy] REJECTED: Access to Debug/Diag ports (Port %d) is blocked from external nodes\n", header->dst_port);
                return false;
            }

            // 2. Restrict Telecommand, File, and Repeater ports to Node 10 only
            if (header->dst_port == PORT_TC || header->dst_port == PORT_FILE || 
                header->dst_port == PORT_RPT || header->dst_port == PORT_CMD) {
                if (header->src_node != 10) {
                    printf("  [Policy] REJECTED: Node %d unauthorized for functional port %d\n", header->src_node, header->dst_port);
                    return false;
                }
            }
        }
    }

    return true;
}
