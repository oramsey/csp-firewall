#ifndef FIREWALL_CORE_H
#define FIREWALL_CORE_H

#include <csp/csp.h>

void firewall_init(void);

/* 
 * The Core now handles explicit packet processing.
 * It takes the two interfaces it's bridging and the packet to evaluate.
 */
void process_packet(csp_iface_t *ground_if, csp_iface_t *space_if, 
                    csp_iface_t *input_if, csp_packet_t *packet);

#endif
