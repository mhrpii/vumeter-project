/*
 * ipg_read.c - Intel Power Gadget okuyucu (Core Ultra 9 285K, 24 cekirdek)
 *
 * IntelPowerGadget.framework API'sini kullanir (PowerLog CLI degil - o bozuk).
 * HWMonitorSMC2 IntelPowerGadget.swift mantigi.
 *
 * Cikti:
 *   pkg_power=15.6   pkg_temp=43   max_temp=105   tdp=125
 *   c0_f=4852  c0_t=45
 *   c1_f=4882  c1_t=45
 *   ...
 *
 * Derleme:
 *   clang -O2 -o ipg_read ipg_read.c \
 *     -F/Library/Frameworks -framework IntelPowerGadget
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <IntelPowerGadget/PowerGadgetLib.h>

int main(void) {
    if (!PG_Initialize()) {
        fprintf(stderr, "PG_Initialize basarisiz (surucu/kext yuklu degil)\n");
        return 1;
    }

    int numCores = 0;
    PG_GetNumCores(0, &numCores);
    if (numCores <= 0) numCores = 1;

    /* Delta gerektiren metrikler icin 2 ornek (aralarinda kisa bekleme) */
    PGSampleID s1, s2;
    PG_ReadSample(0, &s1);
    usleep(200000);   /* 200 ms */
    PG_ReadSample(0, &s2);

    /* --- Paket geneli --- */
    double watts = 0, joules = 0, ptemp = 0, tdp = 0;
    uint8_t maxt = 0;
    PGSample_GetPackagePower(s1, s2, &watts, &joules);
    PGSample_GetPackageTemperature(s2, &ptemp);
    PG_GetMaxTemperature(0, &maxt);
    PG_GetTDP(0, &tdp);

    printf("pkg_power=%.1f\n", watts);
    printf("pkg_temp=%.0f\n", ptemp);
    printf("max_temp=%d\n", maxt);
    printf("tdp=%.0f\n", tdp);
    printf("num_cores=%d\n", numCores);

    /* --- Her cekirdek: frekans + sicaklik --- */
    for (int c = 0; c < numCores; c++) {
        double fmean = 0, fmin = 0, fmax = 0;
        double tmean = 0, tmin = 0, tmax = 0;
        PGSample_GetIACoreFrequency(s1, s2, c, &fmean, &fmin, &fmax);
        PGSample_GetIACoreTemperature(s2, c, &tmean, &tmin, &tmax);
        printf("c%d_f=%.0f  c%d_t=%.0f\n", c, fmean, c, tmean);
    }

    PGSample_Release(s1);
    PGSample_Release(s2);
    PG_Shutdown();
    return 0;
}
