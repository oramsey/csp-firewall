#ifndef POLICY_ENGINE_H
#define POLICY_ENGINE_H
#include <csp/csp.h>
#include "parser.h"
bool is_allowed(firewall_header_t *header, const uint8_t *payload, size_t payload_len);
#endif
