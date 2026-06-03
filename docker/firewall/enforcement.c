#include "enforcement.h"
#include <stdio.h>
#include <csp/csp.h>

// Forward declaration of internal libcsp function
extern int csp_send_direct(csp_id_t idout, csp_packet_t * packet, const csp_route_t * ifroute, uint32_t timeout);

void enforce_policy(bool allowed, csp_iface_t *if_out, csp_packet_t *packet, uint8_t via) {
    if (allowed && if_out != NULL) {
        printf("  [Enforcement] ALLOWED: Transmitting via '%s'\n", if_out->name);
        fflush(stdout);
        
        // Construct a temporary route for this specific packet
        csp_route_t route;
        route.iface = if_out;
        route.via = via;

        if (csp_send_direct(packet->id, packet, &route, 0) != CSP_ERR_NONE) {
            printf("  [Enforcement] ERROR: Physical transmission failed\n");
            csp_buffer_free(packet);
        }
    } else {
        printf("  [Enforcement] DROPPED: Security policy violation\n");
        fflush(stdout);
        csp_buffer_free(packet);
    }
}
