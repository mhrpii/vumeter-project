// mic_permission.m - macOS mikrofon iznini DOGRUDAN ister (AVFoundation).
// ONEMLI: istem ana thread + run loop icinden cagrilmali, yoksa macOS
// pencereyi geciktiriyor (~45sn). Run loop ile aninda gorunur.
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

static volatile int bitti = 0;
static volatile int sonuc = 0;

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        AVAuthorizationStatus st =
            [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];

        if (st == AVAuthorizationStatusAuthorized) { printf("IZIN_VAR\n"); return 0; }
        if (st == AVAuthorizationStatusDenied)     { printf("IZIN_REDDEDILDI\n"); return 2; }
        if (st == AVAuthorizationStatusRestricted) { printf("IZIN_KISITLI\n"); return 3; }

        // NotDetermined -> istemi GOSTER (ana thread, run loop pompalanir)
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
            sonuc = granted ? 1 : 0;
            bitti = 1;
        }];

        // Run loop'u dondur: istem penceresi ANINDA gorunur
        NSDate *son = [NSDate dateWithTimeIntervalSinceNow:120.0];
        while (!bitti && [son timeIntervalSinceNow] > 0) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }

        if (!bitti) { printf("IZIN_ZAMAN_ASIMI\n"); return 4; }
        printf(sonuc ? "IZIN_VERILDI\n" : "IZIN_VERILMEDI\n");
        return sonuc ? 0 : 1;
    }
}
