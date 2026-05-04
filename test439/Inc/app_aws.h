#ifndef APP_AWS_H
#define APP_AWS_H

#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "aws_config.h"

#define COMMAND_QUEUE_LENGTH    10

typedef struct {
    char topic[64];
    char payload[256];
    uint16_t payload_length;
} CommandMessage_t;

typedef struct {
    char device_id[32];
    uint32_t telemetry_interval_ms;
    uint32_t telemetry_counter;
    TaskHandle_t mqtt_task_handle;
    QueueHandle_t command_queue;
    BaseType_t mqtt_connected;
} AppAwsContext_t;

extern AppAwsContext_t g_app_aws_ctx;

void vTelemetryTask(void *pvParameters);
void vCommandHandlerTask(void *pvParameters);

BaseType_t app_aws_publish_telemetry(const char *topic, const char *payload, uint16_t len);
BaseType_t app_aws_get_connection_status(void);
void app_aws_set_connection_status(BaseType_t connected);

#endif