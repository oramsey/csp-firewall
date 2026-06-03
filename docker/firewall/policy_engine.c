#include "policy_engine.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PORT_TC 10
#define PORT_CMD 12
#define PORT_DBG 13
#define PORT_DIAG 14

bool is_allowed(firewall_header_t *header, const uint8_t *payload, size_t payload_len) {
    if (!header) return false;

    // Node Policy
    const char* node_env = getenv("NODE_POLICY_ENABLED");
    if (node_env && strcmp(node_env, "1") == 0) {
        if (header->dst_node == 1 && header->src_node != 10) {
            printf("  [Policy] REJECTED: Node %d unauthorized for satellite access\n", header->src_node);
            fflush(stdout);
            return false;
        }
    }

    // Port Policy
    const char* port_env = getenv("PORT_POLICY_ENABLED");
    if (port_env && strcmp(port_env, "1") == 0) {
        if (header->dst_node == 1) {
            if (header->dst_port == PORT_DBG || header->dst_port == PORT_DIAG) {
                printf("  [Policy] REJECTED: Port %d blocked\n", header->dst_port);
                fflush(stdout);
                return false;
            }
        }
    }

    // Payload Policy
    const char* payload_env = getenv("PAYLOAD_POLICY_ENABLED");
    if (payload_env && strcmp(payload_env, "1") == 0) {
        if (header->dst_node == 1 && (header->dst_port == PORT_TC || header->dst_port == PORT_CMD)) {
            const char* deny[] = {"obc_reset", "obc_system", "obc_exit"};
            for (int i = 0; i < 3; i++) {
                if (payload && strstr((const char*)payload, deny[i])) {
                    printf("  [Policy] REJECTED: Command '%s' blocked\n", deny[i]);
                    fflush(stdout);
                    return false;
                }
            }
        }
    }
    return true;
}
