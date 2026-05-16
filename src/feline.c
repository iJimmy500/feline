#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_CMD 256

static const char *COMMANDS[] = {
    "download", "convert", "clean", "context",
    "snap", "search", "scrape", "lock",
    NULL
};

static void print_usage(void) {
    fprintf(stderr, "Usage: feline <command> [args]\n\n");
    fprintf(stderr, "Commands:\n");
    for (int i = 0; COMMANDS[i]; i++)
        fprintf(stderr, "  %s\n", COMMANDS[i]);
    fprintf(stderr, "\nRun 'feline <command> --help' for usage on a specific command.\n");
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        print_usage();
        return 1;
    }

    if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
        print_usage();
        return 0;
    }

    if (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0) {
        printf("feline 1.0.0\n");
        return 0;
    }

    char cmd[MAX_CMD];
    if (snprintf(cmd, sizeof(cmd), "feline-%s", argv[1]) >= (int)sizeof(cmd)) {
        fprintf(stderr, "feline: command name too long\n");
        return 1;
    }

    /* argv[1] becomes the new argv[0] for the subcommand */
    argv[1] = cmd;
    execvp(cmd, &argv[1]);

    /* execvp only returns on failure */
    fprintf(stderr, "feline: '%s' is not a feline command. See 'feline --help'.\n", argv[1] + 7);
    return 127;
}
