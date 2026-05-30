#ifndef PARSER_H
#define PARSER_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

typedef struct {
    uint8_t prio;
    uint8_t src_node;
    uint8_t dst_node;
    uint8_t dst_port;
    uint8_t src_port;
    uint8_t flags;
    bool valid;
} csp_header_t;

csp_header_t parse_packet(const uint8_t *data, size_t len);

#endif
