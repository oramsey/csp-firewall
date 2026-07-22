#include "firewall_core.h"
#include "parser.h"
#include "policy_engine.h"
#include "enforcement.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// GomSpace ZMQhub internal structure to get the 'via' address
typedef struct {
    uint8_t via;
    uint8_t padding[CSP_PADDING_BYTES - sizeof(uint8_t)];
    uint16_t length;
    csp_id_t id;
} zmqhub_packet_t;

// Forward declaration of internal libcsp function
extern int csp_send_direct(csp_id_t idout, csp_packet_t * packet, const csp_route_t * ifroute, uint32_t timeout);

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

    // 3. Extract 'via' address (Critical for ZMQ to work)
    uint8_t via = ((zmqhub_packet_t *)packet)->via;

    // 4. Check for Bypass Mode (WITHOUT firewall scenario)
    const char *bypass_env = getenv("BYPASS");
    if (bypass_env && strcmp(bypass_env, "1") == 0) {
        csp_route_t route;
        route.iface = output_if;
        route.via = via;
        if (csp_send_direct(packet->id, packet, &route, 0) != CSP_ERR_NONE) {
            csp_buffer_free(packet);
        }
        return;
    }

    printf("[Core] %s: %d -> %d (Port %d)\n", direction_str, h.src_node, h.dst_node, h.dst_port);
    fflush(stdout);

    // 5. Evaluate Security Policy with microbenchmarking
    struct timespec ts_start, ts_end;
    clock_gettime(CLOCK_MONOTONIC, &ts_start);

    bool allowed = is_allowed(&h, packet->data, packet->length);

    clock_gettime(CLOCK_MONOTONIC, &ts_end);
    double elapsed_us = (ts_end.tv_sec - ts_start.tv_sec) * 1000000.0 + (ts_end.tv_nsec - ts_start.tv_nsec) / 1000.0;
    printf("  [Policy] Evaluation took %.3f us\n", elapsed_us);
    fflush(stdout);
    
    // 6. Enforce the decision
    enforce_policy(allowed, output_if, packet, via);
    
    printf("------------------------------\n");
    fflush(stdout);
}
