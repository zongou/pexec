#include <libgen.h>
#include <sys/wait.h>

#include "utils/command.c"
#include "utils/stringutils.c"

int main(int argc, char **argv) {
  char *proot_path = get_tool_path("proot");
  if (proot_path == NULL) {
    fprintf(stderr, "proot not found\n");
    return 1;
  }

  char resolved_path[PATH_MAX];
  char *r = realpath(argv[0], resolved_path);
  char *rootfs_dir = my_asprintf("%s/%s", dirname(realpath(argv[0], resolved_path)), "rootfs");

  char *glibc_str = "aarch64-linux-gnu";
  char *musl_str = "aarch64-linux-musl";
  char *glibc_linker = "ld-linux-aarch64.so.1";
  char *musl_linker = "ld-musl-aarch64.so.1";

  char **proot_argv;
  strlist_add(&proot_argv, proot_path);
  strlist_add(&proot_argv, "--change-id=1000:1000");
  strlist_add(&proot_argv, "--kill-on-exit");
  strlist_add(&proot_argv, my_asprintf("--bind=%s/etc/resolv.conf:/etc/resolv.conf", rootfs_dir));
  strlist_add(&proot_argv, my_asprintf("--bind=%s/etc/hosts:/etc/hosts", rootfs_dir));
  strlist_add(&proot_argv, my_asprintf("--bind=%s/%s:/usr/lib/%s", rootfs_dir, glibc_str, glibc_str));
  strlist_add(&proot_argv, my_asprintf("--bind=%s/%s/%s:/lib/%s", rootfs_dir, glibc_str, glibc_linker, glibc_linker));
  strlist_add(&proot_argv, my_asprintf("--bind=%s/%s:/usr/lib/%s", rootfs_dir, musl_str, musl_str));
  strlist_add(&proot_argv, my_asprintf("--bind=%s/%s/%s:/lib/%s", rootfs_dir, musl_str, musl_linker, musl_linker));
  strlist_add(&proot_argv, my_asprintf("--bind=/system/bin/env:/usr/bin/env"));
  strlist_add(&proot_argv, my_asprintf("--bind=/system/bin/sh:/bin/sh"));

  for (int i = 1; i < argc; i++) {
    strlist_add(&proot_argv, argv[i]);
  }

  // strlist_list(proot_argv, "proot_argv");
  unsetenv("LD_PRELOAD");
  setenv("LD_LIBRARY_PATH", my_asprintf("/usr/lib/%s", musl_str), 1);

  if (argc > 1) {
    char *filecommand_path = get_tool_path("file");
    if (filecommand_path != NULL) {
      int pipe_fds[2];
      pid_t pid;
      FILE *pipe_stream;

      if (pipe(pipe_fds) == -1) {
        perror("pipe");
        return 1;
      }

      pid = fork();
      if (pid < 0) {
        fprintf(stderr, "fork failed\n");
        return 1;
      } else if (pid == 0) {
        close(pipe_fds[0]);

        if (dup2(pipe_fds[1], STDOUT_FILENO) == -1) {
          perror("dup2");
          return 1;
        }

        char *checker_argv[] = {filecommand_path, argv[1], NULL};
        execve(checker_argv[0], checker_argv, NULL);
      } else {
        close(pipe_fds[1]);
        pipe_stream = fdopen(pipe_fds[0], "r");
        if (pipe_stream == NULL) {
          perror("fdopen");
          return 1;
        } else {
          char *line = NULL;
          size_t len = 0;
          ssize_t read;

          while ((read = getline(&line, &len, pipe_stream)) != -1) {
            if (strstr(line, glibc_linker) != NULL) {
              setenv("LD_LIBRARY_PATH", my_asprintf("/usr/lib/%s", glibc_str), 1);
              break;
            }
          }

          free(line);
          fclose(pipe_stream);
          close(pipe_fds[0]);
          wait(NULL);
        }
      }
    } else {
      printf("command file not found\n");
    }
  }

  execvp(proot_argv[0], proot_argv);
  return 0;
}
