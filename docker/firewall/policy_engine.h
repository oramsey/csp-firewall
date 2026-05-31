#ifndef POLICY_ENGINE_H
#define POLICY_ENGINE_H

#include "parser.h"
#include <stddef.h>

bool is_allowed(csp_header_t *header, const uint8_t *payload, size_t payload_len);

#endif
