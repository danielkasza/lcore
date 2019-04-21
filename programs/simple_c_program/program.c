#include <stdio.h>

int main(int argc, char *argv[]) {
    unsigned i, j;

    printf("Just checking: %s\n", "good :)");

    for (i=1; i<16; i++) {
        for (j=1; j<16; j++) {
            printf("%d * %d = %d\n", i, j, (i*j));
        }
    }
    return 0;
}
