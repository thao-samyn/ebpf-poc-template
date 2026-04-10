#include <stdio.h>
#include <signal.h>
#include "template.skel.h"

static volatile bool running = true;
void sig_handler(int sig) { running = false; }

int main() {
    struct template_bpf *skel = template_bpf__open_and_load();
    template_bpf__attach(skel);
    signal(SIGINT, sig_handler);

    // TODO: events loop here

    template_bpf__destroy(skel);
    return 0;
}