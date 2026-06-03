#include "parser.h"
firewall_header_t parse_csp_packet(csp_packet_t *packet) {
    firewall_header_t header = {0};
    if (!packet) return header;
    header.prio = packet->id.pri;
    header.src_node = packet->id.src;
    header.dst_node = packet->id.dst;
    header.src_port = packet->id.sport;
    header.dst_port = packet->id.dport;
    header.flags = packet->id.flags;
    return header;
}
