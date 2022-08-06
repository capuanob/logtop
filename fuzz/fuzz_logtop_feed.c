#include <stdint.h> // uint8_t
#include <string.h> // strlen, memcpy

#include "../src/logtop.h"

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    struct logtop *logtop;
    struct logtop_state *state;
    size_t i;

    // Null-terminate a non-const copy of fuzzer data
    char buf[size];
    memcpy(buf, data, size);
    buf[size - 1] = '\0';

    logtop = new_logtop(10000); /* Don't keep more than 10k elements */

    // Feed all null-terminated strings
    i = 0;
    while (i < size) {
        logtop_feed(logtop, buf + i);
        i += 1 + strlen(buf + i);
    }

    state = logtop_get(logtop, 10); /* Get the top 10 */

    // Cleanup
    delete_logtop_state(state);
    delete_logtop(logtop);
    return 0;
}
