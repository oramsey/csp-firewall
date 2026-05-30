#include "parser.h"

csp_header_t parse_packet(const uint8_t *data, size_t len) {
    csp_header_t header = {0};
    
    if (len < 5) {
        header.valid = false;
        return header;
    }
    
    // Parse Little Endian 32-bit integer (bytes 1 to 4)
    uint32_t hdr_int = (data[4] << 24) | (data[3] << 16) | (data[2] << 8) | data[1];
    
    header.prio = (hdr_int >> 30) & 0x03;
    header.src_node = (hdr_int >> 25) & 0x1f;
    header.dst_node = (hdr_int >> 20) & 0x1f;
    header.dst_port = (hdr_int >> 14) & 0x3f;
    header.src_port = (hdr_int >> 8) & 0x3f;
    header.flags = hdr_int & 0xff;
    header.valid = true;
    
    return header;
}
