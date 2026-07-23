/* VU Meter LCD - .app ana calistirilabilir.
   Amac: sorumlu surec .app'in kendisi olsun (TCC mikrofon izni icin sart).
   python'u COCUK surec olarak baslatir ve bekler; exec KULLANMAZ. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <libgen.h>
#include <limits.h>
#include <mach-o/dyld.h>

int main(int argc, char **argv) {
    char exe[PATH_MAX];
    uint32_t sz = sizeof(exe);
    if (_NSGetExecutablePath(exe, &sz) != 0) return 1;

    /* .../Contents/MacOS/launcher -> .../Contents/Resources/app */
    char dir[PATH_MAX];
    strncpy(dir, exe, sizeof(dir) - 1);
    dir[sizeof(dir) - 1] = 0;
    char *macos = dirname(dir);          /* .../Contents/MacOS */
    char contents[PATH_MAX];
    strncpy(contents, macos, sizeof(contents) - 1);
    contents[sizeof(contents) - 1] = 0;
    char *cts = dirname(contents);       /* .../Contents */

    char appdir[PATH_MAX];
    snprintf(appdir, sizeof(appdir), "%s/Resources/app", cts);
    if (chdir(appdir) != 0) {
        fprintf(stderr, "app dizini bulunamadi: %s\n", appdir);
        return 1;
    }

    /* log dosyasi */
    char logpath[PATH_MAX];
    const char *home = getenv("HOME");
    snprintf(logpath, sizeof(logpath), "%s/Library/Logs/vumeter_launcher.log",
             home ? home : "/tmp");

    /* onceki kopyalari temizle */
    system("pkill -f native_proto_mac 2>/dev/null; pkill -f 'cava -p' 2>/dev/null");
    sleep(2);

    setenv("PATH", "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin", 1);

    pid_t pid = fork();
    if (pid < 0) return 1;
    if (pid == 0) {
        freopen(logpath, "a", stdout);
        freopen(logpath, "a", stderr);
        execl("/usr/bin/python3", "python3", "-u", "native_proto_mac.py", "Spektrum", (char *)NULL);
        _exit(127);
    }
    int st = 0;
    waitpid(pid, &st, 0);   /* launcher HAYATTA kalir - sorumlu surec .app olur */
    return WIFEXITED(st) ? WEXITSTATUS(st) : 1;
}
