#include "routes.h"
#include <csp/csp.h>

void routes_init(csp_iface_t *g, csp_iface_t *s) {
    /*
     * In the "Explicit Loop" architecture, we don't need to set up
     * standard routing or hooks. The main loop manually pulls packets 
     * and decides where to send them.
     */
    printf("Routing logic (Manual Loop) configured.\n");
    fflush(stdout);
}
