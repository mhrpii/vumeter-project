// vu_launcher.m - VU Meter LCD .app ana calistirilabiliri
// 1) AVFoundation ile mikrofon iznini ister (SABIT ikili -> izin kalici)
// 2) python3 ile uygulamayi baslatir (izin surec agacinda miras kalir)
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <unistd.h>
#include <libgen.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <sys/wait.h>

static volatile int g_bitti = 0;

static void izin_al(void) {
    AVAuthorizationStatus st =
        [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (st == AVAuthorizationStatusAuthorized) return;
    if (st != AVAuthorizationStatusNotDetermined) return;

    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                             completionHandler:^(BOOL granted) { g_bitti = 1; }];
    NSDate *son = [NSDate dateWithTimeIntervalSinceNow:120.0];
    while (!g_bitti && [son timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

int main(int argc, char **argv) {
    @autoreleasepool {
        // Mikrofon izni: kaldirilinca ses gelmedi -> gerekli. Zaten izin varsa
        // istem gostermez (authorizationStatus kontrolu ile), sadece ilk
        // kurulumda bir kez sorar.
        izin_al();

        // CAVA IZIN ISITMA: cava'yi once .app'in DOGRUDAN cocugu olarak calistir.
        // TCC izni surec agacinda miras kalir; python'un subprocess ile actigi
        // cava zincirin ucunda kalinca izinsiz oluyordu.
        system("/usr/local/bin/cava -p \"$HOME/.config/cava/config_native\" >/dev/null 2>&1 & sleep 2; pkill -f 'cava -p' 2>/dev/null");

        // CIFT KOPYA KORUMASI: eski surecler USB panele ayni anda yazinca
        // panel kilitlenir (marka ekrani). Once temizle.
        system("pkill -f native_proto_mac 2>/dev/null; pkill -f 'cava -p' 2>/dev/null");
        sleep(2);

        char exe[PATH_MAX]; uint32_t sz = sizeof(exe);
        if (_NSGetExecutablePath(exe, &sz) != 0) return 1;
        char d1[PATH_MAX]; strncpy(d1, exe, sizeof(d1)-1); d1[sizeof(d1)-1] = 0;
        char *macos = dirname(d1);
        char d2[PATH_MAX]; strncpy(d2, macos, sizeof(d2)-1); d2[sizeof(d2)-1] = 0;
        char *contents = dirname(d2);

        char appdir[PATH_MAX];
        snprintf(appdir, sizeof(appdir), "%s/Resources/app", contents);
        if (chdir(appdir) != 0) return 1;

        setenv("PATH", "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin", 1);

        // cikti gunlugu (tray/ses sorunlarini teshis icin)
        const char *home = getenv("HOME");
        char logp[PATH_MAX];
        snprintf(logp, sizeof(logp), "%s/Library/Logs/vumeter_launcher.log",
                 home ? home : "/tmp");
        freopen(logp, "a", stdout);
        freopen(logp, "a", stderr);

        // exec YERINE fork: launcher hayatta kalir -> .app kimligi korunur
        // (execl ile surec python'a donusunce macOS menu cubugu hakkini kaybediyor)
        pid_t pid = fork();
        if (pid < 0) return 1;
        if (pid == 0) {
            execl("/usr/bin/python3", "python3", "-u", "native_proto_mac.py", "Spektrum", (char *)NULL);
            _exit(127);
        }
        int st = 0;
        waitpid(pid, &st, 0);
        return WIFEXITED(st) ? WEXITSTATUS(st) : 1;
    }
}
