#include "app_aws.h"
#include "aws_config.h"
#include <stdio.h>
#include <string.h>

AppAwsContext_t g_app_aws_ctx;

static void prvCommandCallback(void *pvParam1, void *pvParam2)
{
    CommandMessage_t *pxMessage = (CommandMessage_t *)pvParam1;
    
    if (pxMessage != NULL) {
        printf("Command received on topic: %s\r\n", pxMessage->topic);
        printf("Payload: %.*s\r\n", pxMessage->payload_length, pxMessage->payload);
    }
}

void vTelemetryTask(void *pvParameters)
{
    TickType_t xLastWakeTime;
    BaseType_t xPublished;
    AppAwsContext_t *pxCtx = &g_app_aws_ctx;
    
    xLastWakeTime = xTaskGetTickCount();
    
    pxCtx->telemetry_interval_ms = TELEMETRY_PUBLISH_INTERVAL_MS;
    pxCtx->telemetry_counter = 0;
    pxCtx->mqtt_connected = pdFALSE;
    
    printf("[Telemetry] Task started, interval: %lu ms\r\n", 
           (unsigned long)pxCtx->telemetry_interval_ms);
    
    while (1) {
        xTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(pxCtx->telemetry_interval_ms));
        
        if (pxCtx->mqtt_connected == pdTRUE) {
            pxCtx->telemetry_counter++;
            
            snprintf(telemetry_payload, sizeof(telemetry_payload),
                    "{\"device\":\"%s\",\"counter\":%lu,\"status\":\"ok\"}",
                    AWS_DEVICE_ID, (unsigned long)pxCtx->telemetry_counter);
            
            xPublished = app_aws_publish_telemetry(
                AWS_IOT_TELEMETRY_TOPIC,
                telemetry_payload,
                strlen(telemetry_payload));
            
            if (xPublished == pdTRUE) {
                printf("[Telemetry] Published #%lu: %s\r\n",
                       (unsigned long)pxCtx->telemetry_counter,
                       telemetry_payload);
            } else {
                printf("[Telemetry] Publish failed\r\n");
            }
        } else {
            printf("[Telemetry] MQTT not connected, skipping\r\n");
        }
    }
}

void vCommandHandlerTask(void *pvParameters)
{
    CommandMessage_t xCommand;
    AppAwsContext_t *pxCtx = &g_app_aws_ctx;
    
    if (pxCtx->command_queue == NULL) {
        printf("[Command] ERROR: Queue not initialized\r\n");
        vTaskDelete(NULL);
        return;
    }
    
    printf("[Command] Handler task started\r\n");
    
    while (1) {
        if (xQueueReceive(pxCtx->command_queue, &xCommand, pdMS_TO_TICKS(1000)) == pdTRUE) {
            prvCommandCallback(&xCommand, NULL);
        }
    }
}

BaseType_t app_aws_publish_telemetry(const char *topic, const char *payload, uint16_t len)
{
    (void)topic;
    (void)payload;
    (void)len;
    
    return pdFALSE;
}

BaseType_t app_aws_get_connection_status(void)
{
    return g_app_aws_ctx.mqtt_connected;
}

void app_aws_set_connection_status(BaseType_t connected)
{
    g_app_aws_ctx.mqtt_connected = connected;
    printf("[AWS] Connection status: %s\r\n", 
           connected ? "CONNECTED" : "DISCONNECTED");
}