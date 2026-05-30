#include "policy_engine.h"
#include <stdio.h>

bool is_allowed(csp_header_t *header) {
    if (!header->valid) {
        printf("  [Policy] REJECTED: Invalid CSP Header\n");
        return false;
    }

    // Placeholder: Allow everything for now
    return true;
}
