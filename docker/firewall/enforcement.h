#ifndef ENFORCEMENT_H
#define ENFORCEMENT_H

#include <csp/csp.h>
#include <stdbool.h>

void enforce_policy(bool allowed, csp_iface_t *if_out, csp_packet_t *packet, uint8_t via);

#endif
