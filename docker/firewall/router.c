#include <zmq.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "firewall_core.h"

int main(void) {
    // Disable output buffering
    setvbuf(stdout, NULL, _IONBF, 0);

    const char *hub_a_ip = getenv("HUB_A_IP");
    const char *hub_b_ip = getenv("HUB_B_IP");
    
    if (!hub_a_ip) hub_a_ip = "ground-node-a";
    if (!hub_b_ip) hub_b_ip = "sat-node-b";

    void *context = zmq_ctx_new();

    // Sockets for Network A (Ground)
    void *sub_a = zmq_socket(context, ZMQ_SUB);
    char addr_sub_a[256];
    snprintf(addr_sub_a, sizeof(addr_sub_a), "tcp://%s:8001", hub_a_ip);
    zmq_connect(sub_a, addr_sub_a);
    zmq_setsockopt(sub_a, ZMQ_SUBSCRIBE, "", 0);

    void *pub_a = zmq_socket(context, ZMQ_PUB);
    char addr_pub_a[256];
    snprintf(addr_pub_a, sizeof(addr_pub_a), "tcp://%s:8002", hub_a_ip);
    zmq_connect(pub_a, addr_pub_a);

    // Sockets for Network B (Space)
    void *sub_b = zmq_socket(context, ZMQ_SUB);
    char addr_sub_b[256];
    snprintf(addr_sub_b, sizeof(addr_sub_b), "tcp://%s:8001", hub_b_ip);
    zmq_connect(sub_b, addr_sub_b);
    zmq_setsockopt(sub_b, ZMQ_SUBSCRIBE, "", 0);

    void *pub_b = zmq_socket(context, ZMQ_PUB);
    char addr_pub_b[256];
    snprintf(addr_pub_b, sizeof(addr_pub_b), "tcp://%s:8002", hub_b_ip);
    zmq_connect(pub_b, addr_pub_b);

    zmq_pollitem_t items[] = {
        { sub_a, 0, ZMQ_POLLIN, 0 },
        { sub_b, 0, ZMQ_POLLIN, 0 }
    };

    printf("Modular C CSP Firewall Router started...\n");
    printf("  Network A (Ground): %s:8001/8002\n", hub_a_ip);
    printf("  Network B (Space):  %s:8001/8002\n", hub_b_ip);

    while (1) {
        int rc = zmq_poll(items, 2, 1000);
        if (rc == -1) break;

        if (items[0].revents & ZMQ_POLLIN) {
            zmq_msg_t msg;
            zmq_msg_init(&msg);
            zmq_msg_recv(&msg, sub_a, 0);
            process_packet(pub_a, pub_b, &msg, A_TO_B);
        }

        if (items[1].revents & ZMQ_POLLIN) {
            zmq_msg_t msg;
            zmq_msg_init(&msg);
            zmq_msg_recv(&msg, sub_b, 0);
            process_packet(pub_a, pub_b, &msg, B_TO_A);
        }
    }

    zmq_close(sub_a);
    zmq_close(pub_a);
    zmq_close(sub_b);
    zmq_close(pub_b);
    zmq_ctx_destroy(context);
    
    return 0;
}
