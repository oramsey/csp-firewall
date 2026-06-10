#include "firewall_core.h"
#include "parser.h"
#include "policy_engine.h"
#include "enforcement.h"
#include <stdio.h>
#include <string.h>

// GomSpace ZMQhub internal structure to get the 'via' address
typedef struct {
    uint8_t via;
    uint8_t padding[CSP_PADDING_BYTES - sizeof(uint8_t)];
    uint16_t length;
    csp_id_t id;
} zmqhub_packet_t;

void firewall_init(void) {
    printf("Firewall Core Active (Explicit Interception Mode).\n");
    fflush(stdout);
}

void process_packet(csp_iface_t *ground_if, csp_iface_t *space_if, 
                    csp_iface_t *input_if, csp_packet_t *packet) {
    if (!packet || !input_if) return;

    firewall_header_t h = parse_csp_packet(packet);
    csp_iface_t *output_if = NULL;
    const char *direction_str = "Unknown";

    // 1. Determine Direction and Output Interface
    if (input_if == ground_if) {
        output_if = space_if;
        direction_str = "GROUND -> SPACE";
    } else if (input_if == space_if) {
        output_if = ground_if;
        direction_str = "SPACE -> GROUND";
    }

    // 2. Loop Prevention (Only forward if it's cross-segment traffic)
    bool should_forward = false;
    if (input_if == ground_if && (h.dst_node == 1 || h.dst_node == 2)) {
        should_forward = true;
    } else if (input_if == space_if && (h.dst_node == 10 || h.dst_node == 11 || h.dst_node == 3)) {
        should_forward = true;
    }

    if (!should_forward) {
        csp_buffer_free(packet);
        return;
    }

    printf("[Core] %s: %d -> %d (Port %d)\n", direction_str, h.src_node, h.dst_node, h.dst_port);
    fflush(stdout);

    // 3. Extract 'via' address (Critical for ZMQ to work)
    uint8_t via = ((zmqhub_packet_t *)packet)->via;

    // 4. Evaluate Security Policy
    bool allowed = is_allowed(&h, packet->data, packet->length);
    
    // 5. Enforce the decision
    enforce_policy(allowed, output_if, packet, via);
    
    printf("------------------------------\n");
    fflush(stdout);
}
