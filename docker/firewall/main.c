#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <csp/csp.h>
#include "firewall_core.h"
#include "iface_zmq.h"

// Internal libcsp queue functions
typedef struct {
    csp_iface_t * iface;
    csp_packet_t * packet;
} csp_qfifo_t;

extern int csp_qfifo_read(csp_qfifo_t * input);

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);

    csp_conf_t c;
    csp_conf_get_defaults(&c);
    c.address = 30;
    csp_init(&c);

    firewall_init();

    const char *h_a = getenv("HUB_A_IP") ? getenv("HUB_A_IP") : "ground-node-a";
    const char *h_b = getenv("HUB_B_IP") ? getenv("HUB_B_IP") : "sat-node-b";

    csp_iface_t *g = iface_zmq_init("ground", h_a);
    csp_iface_t *s = iface_zmq_init("space", h_b);

    if (!g || !s) {
        printf("CRITICAL ERROR: Could not initialize interfaces\n");
        return -1;
    }

    printf("Generic CSP App Firewall Started (Manual Interception Loop)\n");
    fflush(stdout);

    /* 
     * THE EXPLICIT LOOP:
     * Instead of letting LibCSP route packets, the Firewall App
     * manually drains the incoming packet queue.
     */
    while (1) {
        csp_qfifo_t input;
        
        // This blocks until a packet arrives on ANY interface
        if (csp_qfifo_read(&input) == CSP_ERR_NONE) {
            process_packet(g, s, input.iface, input.packet);
        }
    }

    return 0;
}
