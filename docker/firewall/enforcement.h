#ifndef ENFORCEMENT_H
#define ENFORCEMENT_H

#include <zmq.h>
#include "parser.h"

typedef enum {
    A_TO_B,
    B_TO_A
} direction_t;

void forward_packet(void *pub_a, void *pub_b, zmq_msg_t *msg, direction_t dir);
void drop_packet(csp_header_t *header);

#endif
