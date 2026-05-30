#include "policy_engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

bool is_allowed(csp_header_t *header) {
    if (!header->valid) {
        printf("  [Policy] REJECTED: Invalid CSP Header\n");
        return false;
    }

    // Check if node-level policy is enabled via environment variable
    const char* policy_env = getenv("NODE_POLICY_ENABLED");
    bool policy_enabled = (policy_env != NULL && strcmp(policy_env, "1") == 0);

    if (policy_enabled) {
        // Rule: Only allow Node 10 (Benign Ground) to send to Node 1 (Satellite)
        if (header->dst_node == 1 && header->src_node != 10) {
            printf("  [Policy] REJECTED: Node %d is not authorized to talk to Node 1\n", header->src_node);
            return false;
        }
    }

    // If policy is disabled or rule passed, allow it
    return true;
}
