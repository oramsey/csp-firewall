#include "firewall_core.h"
#include "parser.h"
#include "policy_engine.h"
#include <stdio.h>

void process_packet(void *pub_a, void *pub_b, zmq_msg_t *msg, direction_t dir) {
    size_t size = zmq_msg_size(msg);
    const uint8_t *data = (const uint8_t *)zmq_msg_data(msg);
    
    csp_header_t header = parse_packet(data, size);
    
    if (!header.valid) {
        zmq_msg_close(msg);
        return;
    }

    // --- ROUTING LOGIC ---
    if (dir == A_TO_B) {
        if (header.dst_node != 1) { // Not space node
            zmq_msg_close(msg);
            return;
        }
    } else if (dir == B_TO_A) {
        if (header.dst_node != 10 && header.dst_node != 11) { // Not ground nodes
            zmq_msg_close(msg);
            return;
        }
    }
    // ---------------------

    const char *dir_str = (dir == A_TO_B) ? "A_TO_B" : "B_TO_A";
    printf("[Core] Incoming: Src: %d, Dst: %d, DPort: %d, SPort: %d, Prio: %d (%s)\n", 
           header.src_node, header.dst_node, header.dst_port, header.src_port, header.prio, dir_str);

    // Deep Packet Inspection: Payload starts after MAC (1 byte) and CSP Header (4 bytes)
    const uint8_t *payload = (size > 5) ? &data[5] : NULL;
    size_t payload_len = (size > 5) ? (size - 5) : 0;

    if (is_allowed(&header, payload, payload_len)) {
        forward_packet(pub_a, pub_b, msg, dir);
    } else {
        drop_packet(&header);
        zmq_msg_close(msg); // Dropped, we must close it
    }
    
    printf("------------------------------\n");
}
