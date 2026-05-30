#include "enforcement.h"
#include <stdio.h>

void forward_packet(void *pub_a, void *pub_b, zmq_msg_t *msg, direction_t dir) {
    int rc;
    if (dir == A_TO_B) {
        rc = zmq_msg_send(msg, pub_b, 0);
        if (rc != -1) printf("  [Enforcement] FORWARDED to Network B (Space)\n");
    } else {
        rc = zmq_msg_send(msg, pub_a, 0);
        if (rc != -1) printf("  [Enforcement] FORWARDED to Network A (Ground)\n");
    }
    
    if (rc == -1) {
        zmq_msg_close(msg); // Close if send failed
    }
}

void drop_packet(csp_header_t *header) {
    printf("  [Enforcement] DROPPED: Src: %d, Dst: %d\n", header->src_node, header->dst_node);
}
