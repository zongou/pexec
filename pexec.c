#include <libgen.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define ROOTFS "rootfs"

int strlist_addl(char ***str_listp, ...) {
  va_list args;
  va_start(args, str_listp);

  int len_to_append = 0;
  va_list args_copy;
  va_copy(args_copy, args);
  while (va_arg(args_copy, char *) != NULL) {
    len_to_append = len_to_append + 1;
  }
  va_end(args_copy);

  int len_source = 0;
  if (*str_listp != NULL) {
    while ((*str_listp)[len_source] != NULL) {
      len_source = len_source + 1;
    }
  }

  char **strlist_tmp = realloc(*str_listp, sizeof(char *) * (len_source + len_to_append + 1));
  if (strlist_tmp == 0) {
    perror("Failed to realloc memory\n");
    return EXIT_FAILURE;
  }
  *str_listp = strlist_tmp;

  for (int i = 0; i < len_to_append; i++) {
    (*str_listp)[len_source + i] = va_arg(args, char *);
  }
  strlist_tmp[len_source + len_to_append] = 0;
  va_end(args);

  return EXIT_SUCCESS;
}

char *my_asprintf(const char *format, ...) {
  // Initialize variable argument list
  va_list args;
  va_start(args, format);

  // First, determine the length of the formatted string
  // We use a temporary copy of the argument list for this
  va_list args_copy;
  va_copy(args_copy, args);
  int len = vsnprintf(NULL, 0, format, args_copy);
  va_end(args_copy);

  // Check if vsnprintf was successful
  if (len < 0) {
    // Error occurred during vsnprintf
    fprintf(stderr, "Error during vsnprintf.\n");
    va_end(args);
    return NULL;
  }

  // Allocate memory for the formatted string
  char *str = malloc(len + 1); // +1 for the null terminator
  if (!str) {
    // Memory allocation failed
    fprintf(stderr, "Memory allocation failed.\n");
    va_end(args);
    return NULL;
  }

  // Now format the string into the allocated memory
  int result = vsnprintf(str, len + 1, format, args);
  if (result < 0) {
    // Error occurred during the second vsnprintf call
    free(str); // Free the allocated memory to avoid a leak
    fprintf(stderr, "Error during vsnprintf while formatting.\n");
    va_end(args);
    return NULL;
  }

  // Clean up the variable argument list
  va_end(args);

  // Return the formatted string
  return str;
}

int main(int argc, char *argv[]) {
  const char *original_path = argv[0];
  char path_copy[1024]; // Ensure this is large enough to hold the path

  strncpy(path_copy, original_path, sizeof(path_copy) - 1);
  path_copy[sizeof(path_copy) - 1] = '\0'; // Ensure null termination

  char *dir = dirname(path_copy);

  //   printf("Original path: %s\n", original_path);
  //   printf("Directory name: %s\n", dir);

  char **proot_argv;
  // strlist_addl(&proot_argv, "echo", NULL);
  strlist_addl(&proot_argv, "proot", NULL);
  strlist_addl(&proot_argv, "--change-id=1000:1000", NULL);
  strlist_addl(&proot_argv, "--kill-on-exit", NULL);
  strlist_addl(&proot_argv, my_asprintf("--bind=%s%s%s%s", dir, "/", ROOTFS, "/etc/resolv.conf:/etc/resolv.conf"), NULL);
  strlist_addl(&proot_argv, my_asprintf("--bind=%s%s%s%s", dir, "/", ROOTFS, "/etc/hosts:/etc/hosts"), NULL);
  strlist_addl(&proot_argv, my_asprintf("--bind=%s%s%s%s", dir, "/", ROOTFS, "/etc/passwd:/etc/passwd"), NULL);
  strlist_addl(&proot_argv, my_asprintf("--bind=%s%s%s%s", dir, "/", ROOTFS, "/aarch64-linux-musl:/usr/lib/aarch64-linux-musl"), NULL);
  strlist_addl(&proot_argv, my_asprintf("--bind=%s%s%s%s", dir, "/", ROOTFS, "/aarch64-linux-musl/ld-musl-aarch64.so.1:/"
                                                                             "lib/ld-musl-aarch64.so.1"),
               NULL);
  strlist_addl(&proot_argv, my_asprintf("--bind=%s%s%s%s", dir, "/", ROOTFS, "/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu"), NULL);
  strlist_addl(&proot_argv, my_asprintf("--bind=%s%s%s%s", dir, "/", ROOTFS, "/aarch64-linux-gnu/ld-linux-aarch64.so.1:/lib/"
                                                                             "ld-linux-aarch64.so.1"),
               NULL);
  strlist_addl(&proot_argv, "--bind=/system/bin/env:/usr/bin/env", NULL);
  // strlist_addl(&proot_argv, "--bind=/system/bin/sh:/bin/sh", NULL);

  unsetenv("LD_PRELOAD");
  for (int i = 1; i < argc; i++) {
    if (i == 1) {
      if (strcmp(argv[i], "--glibc") == 0) {
        if (setenv("LD_LIBRARY_PATH", "/usr/lib/aarch64-linux-gnu", 1) != 0) {
          perror("Failed to set LD_LIBRARY_PATH");
          return EXIT_FAILURE;
        }
      } else {
        if (setenv("LD_LIBRARY_PATH", "/usr/lib/aarch64-linux-musl", 1) != 0) {
          perror("Failed to set LD_LIBRARY_PATH");
          return EXIT_FAILURE;
        }
        strlist_addl(&proot_argv, argv[i], NULL);
      }
    } else {
      strlist_addl(&proot_argv, argv[i], NULL);
    }
  }

  execvp(proot_argv[0], proot_argv);

  // If execv returns, it must have failed
  //   perror("execv"); // Print the error message
  return 1; // Return a non-zero value to indicate failure
}
