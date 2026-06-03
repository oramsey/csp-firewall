#include "iface_zmq.h"
#include <csp/interfaces/csp_if_zmqhub.h>
#include <stdio.h>

csp_iface_t *iface_zmq_init(const char *name, const char *host) {
    csp_iface_t *iface = NULL;
    char pub[128], sub[128];
    snprintf(pub, 128, "tcp://%s:8002", host);
    snprintf(sub, 128, "tcp://%s:8001", host);
    if (csp_zmqhub_init_w_name_endpoints_rxfilter(name, NULL, 0, pub, sub, 0, &iface) != CSP_ERR_NONE) return NULL;
    printf("Initialized %s interface at %s\n", name, host);
    fflush(stdout);
    return iface;
}
