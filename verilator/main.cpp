#include "Vcpu.h"
#include <poll.h>

Vcpu *cpu;

static bool stdin_pending;
static char stdin_char;
/* Update state of standard input. */
static void standard_input_update(void) {
    struct pollfd fd = {
        .fd = 0, /* stdin */
        .events = POLLIN,
    };

    /* Is our port selected? */
    if (cpu->io_port == 2) {
        /* Yes.
         * Is it read or write?
         */
        if (cpu->data_out_valid) {
            /* Write. Discard character if pending. */
            stdin_pending = false;
        } else if (stdin_pending) {
            /* Read and we have data. */
            cpu->data_in = stdin_char;
        } else {
            /* Read, but we don't have data. */
            cpu->data_in = 1<<15;
        }
    }

    /* Try to get next char if we don't have one buffered already. */
    if (!stdin_pending && (poll(&fd, 1, 0) > 0)) {
        int c = getchar();
        if (c != EOF) {
            stdin_char = c;
            stdin_pending = true;
        }
    }
}

/* Update state of standard output. */
static void standard_output_update(void) {
    /* Is our port selected? */
    if (cpu->io_port == 3) {
        /* Yes.
         * Is it read or write?
         */
        if (cpu->data_out_valid) {
            /* Write. */
            putchar(cpu->data_out);
        } else {
            /* Read. We can always accept more data. */
            cpu->data_in = 1;
        }
    }
}

uint16_t interrupt_mask = 0;
/* Update stat of interrupt controller. */
static void interrupt_update(void) {
    /* Handle interrupt mask. */
    if (cpu->io_port == 5) {
        if (cpu->data_out_valid) {
            interrupt_mask = cpu->data_out;
        } else {
            cpu->data_in = interrupt_mask;
        }
    }

    /* Update interrupt status.
     * Standard output interrupt is always pending.
     */
    uint16_t interrupt_pending =  (stdin_pending ? 1:0) | 2;
    uint16_t interrupt_status = interrupt_mask & interrupt_pending;

    /* Assert interrupt request if we have to. */
    cpu->irq = (interrupt_status != 0);

    /* Handle interrupt status access. */
    if (cpu->io_port == 4) {
        cpu->data_in = interrupt_status;
    }
}

int main() {
    cpu = new Vcpu;

    setvbuf(stdin,  NULL, _IONBF, 0);
    setvbuf(stdout, NULL, _IONBF, 0);

    unsigned i;
    for(i=1;;i++) {
        cpu->clock = 0;
        cpu->eval();
        cpu->clock = 1;
        cpu->eval();

        /* Handle end of program. */
        if (cpu->data_out_valid && (cpu->io_port == 0)) {
            break;
        }

        standard_input_update();
        standard_output_update();
        interrupt_update();
    }

done:
    return 0;
}
