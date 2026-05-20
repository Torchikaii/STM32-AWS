#ifndef SNTP_TASK_H
#define SNTP_TASK_H

#include <time.h>

extern volatile time_t g_unix_epoch;

void Start_SntpTask(void *argument);

#endif
