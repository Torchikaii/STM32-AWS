#ifndef AWS_MQTT_H
#define AWS_MQTT_H

#include "lwip/apps/mqtt_client.h"
#include "aws_config.h"

typedef enum {
    AWS_MQTT_STATE_DISCONNECTED = 0,
    AWS_MQTT_STATE_CONNECTING,
    AWS_MQTT_STATE_CONNECTED,
    AWS_MQTT_STATE_ERROR
} aws_mqtt_state_t;

typedef void (*aws_mqtt_command_cb_t)(const char *topic, const uint8_t *data, uint16_t len);

typedef struct {
    aws_mqtt_state_t state;
    mqtt_client_t *client;
    ip_addr_t server_ip;
    aws_mqtt_command_cb_t command_callback;
    void *user_arg;
} aws_mqtt_handle_t;

err_t aws_mqtt_connect(aws_mqtt_handle_t *handle);
void aws_mqtt_disconnect(aws_mqtt_handle_t *handle);
err_t aws_mqtt_publish(aws_mqtt_handle_t *handle, const char *topic, const uint8_t *data, uint16_t len);
err_t aws_mqtt_subscribe_command(aws_mqtt_handle_t *handle, aws_mqtt_command_cb_t callback, void *arg);
aws_mqtt_state_t aws_mqtt_get_state(aws_mqtt_handle_t *handle);

#endif
