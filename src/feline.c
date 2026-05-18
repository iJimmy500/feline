#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>

#define MAX_CMD  256
#define MAX_PATH 512

#define UPDATE_INTERVAL 86400  /* 1 day in seconds */

static const char *COMMANDS[] = {
    "download", "convert", "clean", "context",
    "snap", "search", "scrape", "lock", "update",
    "settings", "ports", "schedule",
    NULL
};

static void maybe_notify_update(void) {
    const char *home = getenv("HOME");
    if (!home) return;
    char flag[MAX_PATH];
    snprintf(flag, sizeof(flag), "%s/.feline/update_available", home);
    if (access(flag, F_OK) == 0) {
        fprintf(stderr, "\033[33mA feline update is available. Run 'feline update' to install it.\033[0m\n");
    }
}

static void maybe_spawn_checker(void) {
    const char *home = getenv("HOME");
    if (!home) return;
    char stamp[MAX_PATH];
    snprintf(stamp, sizeof(stamp), "%s/.feline/last_update_check", home);

    struct stat st;
    if (stat(stamp, &st) == 0 && difftime(time(NULL), st.st_mtime) < UPDATE_INTERVAL)
        return;

    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        int devnull = open("/dev/null", O_WRONLY);
        if (devnull >= 0) {
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
        execlp("feline-update-check", "feline-update-check", NULL);
        _exit(1);
    }
}

static void print_usage(void) {
    fprintf(stderr, "Usage: feline <command> [args]\n\n");
    fprintf(stderr, "Commands:\n");
    for (int i = 0; COMMANDS[i]; i++)
        fprintf(stderr, "  %s\n", COMMANDS[i]);
    fprintf(stderr, "\nRun 'feline <command> --help' for usage on a specific command.\n");
    fprintf(stderr, "Run 'feline --credits' for license and author information.\n");
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
        printf("feline 1.1.0\n");
        return 0;
    }

    if (strcmp(argv[1], "--credits") == 0) {
        printf("feline 1.1.0  (experimental)\n");
        printf("Copyright (c) 2026 james006\n");
        printf("\n");
        printf("Licensed under the feline Community License v1.0\n");
        printf("https://github.com/iJimmy500/feline\n");
        printf("\n");
        printf("WARNING: This software is experimental. Features may change\n");
        printf("or break without notice. Use at your own risk.\n");
        return 0;
    }

    maybe_notify_update();
    maybe_spawn_checker();

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
