#define main nmap_main
#include "main.c"
#undef main

#include <assert.h>

static void expect_valid(const char *spec, const uint16_t *expected, int expected_count) {
    uint16_t *ports = NULL;
    int count = 0;

    assert(parse_port_spec(spec, &ports, &count) == 0);
    assert(count == expected_count);
    for (int i = 0; i < count; i++) {
        assert(ports[i] == expected[i]);
    }
    free(ports);
}

static void expect_invalid(const char *spec) {
    uint16_t *ports = NULL;
    int count = 0;

    assert(parse_port_spec(spec, &ports, &count) == -1);
    assert(ports == NULL);
    assert(count == 0);
}

int main(void) {
    static const uint16_t one[] = {80};
    static const uint16_t range[] = {22, 23, 24};
    static const uint16_t list[] = {22, 80, 443, 3306};
    static const uint16_t deduplicated[] = {22, 23, 80};
    static const uint16_t spaced[] = {22, 23, 24, 80};
    uint16_t *all_ports = NULL;
    int all_ports_count = 0;

    expect_valid("80", one, 1);
    expect_valid("22-24", range, 3);
    expect_valid("22,80,443,3306", list, 4);
    expect_valid("80,22,80,22-23", deduplicated, 3);
    expect_valid(" 22 - 24 , 80 ", spaced, 4);
    assert(parse_port_spec("1-65535", &all_ports, &all_ports_count) == 0);
    assert(all_ports_count == 65535 && all_ports[0] == 1 && all_ports[65534] == 65535);
    free(all_ports);

    expect_invalid("0-10");
    expect_invalid("65536");
    expect_invalid("24-22");
    expect_invalid("80,,443");
    expect_invalid("");

    puts("port parser checks passed");
    return 0;
}
