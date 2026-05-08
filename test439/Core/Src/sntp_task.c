#include "sntp_task.h"
#include "lwip/apps/sntp.h"
#include "cmsis_os2.h"
#include <stdio.h>

volatile time_t g_unix_epoch = 0;

static void sntp_sync_callback(uint32_t secs, uint32_t frac, int8_t offset)
{
    (void)frac;
    (void)offset;
    g_unix_epoch = (time_t)secs;
}

time_t platform_time(time_t *t)
{
    time_t now = g_unix_epoch;
    if (t) *t = now;
    return now;
}

void Start_SntpTask(void *argument)
{
    (void)argument;

    sntp_setoperatingmode(SNTP_OPMODE_POLL);
    sntp_setservername(0, "pool.ntp.org");
    sntp_set_sync_callback(sntp_sync_callback);
    sntp_init();

    printf("[SNTP] Waiting for time sync...\n");
    while (g_unix_epoch == 0) {
        osDelay(100);
    }
    printf("[SNTP] Time synced: %lu\n", (unsigned long)g_unix_epoch);

    for (;;) {
        osDelay(60000);
    }
}
