#ifndef FIREWALL_CORE_H
#define FIREWALL_CORE_H

#include <zmq.h>
#include "enforcement.h"

void process_packet(void *pub_a, void *pub_b, zmq_msg_t *msg, direction_t dir);

#endif
