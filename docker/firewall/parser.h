#ifndef PARSER_H
#define PARSER_H
#include <csp/csp.h>
#include <stdbool.h>
typedef struct {
    uint8_t prio, src_node, dst_node, dst_port, src_port, flags;
} firewall_header_t;
firewall_header_t parse_csp_packet(csp_packet_t *packet);
#endif
