#include "aws_mqtt.h"
#include "lwip/netdb.h"
#include <string.h>

static void mqtt_connection_callback(mqtt_client_t *client, void *arg, mqtt_connection_status_t status);
static void mqtt_incoming_publish_cb(void *arg, const char *topic, u32_t tot_len);
static void mqtt_incoming_data_cb(void *arg, const u8_t *data, u16_t len, u8_t flags);
static void mqtt_pub_request_cb(void *arg, err_t err);

extern struct mqtt_connect_client_info_t mqtt_client_info;

static char rx_buffer[AWS_MQTT_RX_BUF_SIZE];
static char rx_topic[64];

void aws_mqtt_disconnect(aws_mqtt_handle_t *handle)
{
    if (handle == NULL || handle->client == NULL) {
        return;
    }
    mqtt_disconnect(handle->client);
    handle->state = AWS_MQTT_STATE_DISCONNECTED;
}

err_t aws_mqtt_connect(aws_mqtt_handle_t *handle)
{
    err_t err;
    struct hostent *server_host;

    if (handle == NULL) {
        return ERR_ARG;
    }

    handle->state = AWS_MQTT_STATE_CONNECTING;

    server_host = netconn_gethostbyname(AWS_IOT_ENDPOINT);
    if (server_host == NULL) {
        handle->state = AWS_MQTT_STATE_ERROR;
        return ERR_VAL;
    }

    ip_addr_copy(handle->server_ip, *((ip_addr_t *)server_host->h_addr_list[0]));

    handle->client = mqtt_client_new();
    if (handle->client == NULL) {
        handle->state = AWS_MQTT_STATE_ERROR;
        return ERR_MEM;
    }

    err = mqtt_client_connect(handle->client, &handle->server_ip, AWS_IOT_PORT,
                              mqtt_connection_callback, handle, &mqtt_client_info);

    if (err != ERR_OK) {
        mqtt_client_free(handle->client);
        handle->client = NULL;
        handle->state = AWS_MQTT_STATE_ERROR;
    }

    return err;
}

err_t aws_mqtt_publish(aws_mqtt_handle_t *handle, const char *topic, const uint8_t *data, uint16_t len)
{
    if (handle == NULL || handle->client == NULL || topic == NULL || data == NULL) {
        return ERR_ARG;
    }

    if (!mqtt_client_is_connected(handle->client)) {
        return ERR_CONN;
    }

    return mqtt_publish(handle->client, topic, data, len, 0, 0, mqtt_pub_request_cb, NULL);
}

err_t aws_mqtt_subscribe_command(aws_mqtt_handle_t *handle, aws_mqtt_command_cb_t callback, void *arg)
{
    if (handle == NULL || handle->client == NULL) {
        return ERR_ARG;
    }

    if (!mqtt_client_is_connected(handle->client)) {
        return ERR_CONN;
    }

    handle->command_callback = callback;
    handle->user_arg = arg;

    mqtt_set_inpub_callback(handle->client, mqtt_incoming_publish_cb, mqtt_incoming_data_cb, handle);

    return mqtt_subscribe(handle->client, AWS_IOT_COMMAND_TOPIC, 0, NULL, NULL);
}

aws_mqtt_state_t aws_mqtt_get_state(aws_mqtt_handle_t *handle)
{
    if (handle == NULL) {
        return AWS_MQTT_STATE_ERROR;
    }
    return handle->state;
}

static void mqtt_connection_callback(mqtt_client_t *client, void *arg, mqtt_connection_status_t status)
{
    aws_mqtt_handle_t *handle = (aws_mqtt_handle_t *)arg;

    if (status == MQTT_CONNECT_ACCEPTED) {
        handle->state = AWS_MQTT_STATE_CONNECTED;
    } else {
        handle->state = AWS_MQTT_STATE_ERROR;
    }
}

static void mqtt_incoming_publish_cb(void *arg, const char *topic, u32_t tot_len)
{
    aws_mqtt_handle_t *handle = (aws_mqtt_handle_t *)arg;

    if (tot_len < sizeof(rx_buffer)) {
        memset(rx_buffer, 0, sizeof(rx_buffer));
    }

    strncpy(rx_topic, topic, sizeof(rx_topic) - 1);
    rx_topic[sizeof(rx_topic) - 1] = 0;
}

static void mqtt_incoming_data_cb(void *arg, const u8_t *data, u16_t len, u8_t flags)
{
    aws_mqtt_handle_t *handle = (aws_mqtt_handle_t *)arg;
    uint16_t current_len = strlen(rx_buffer);

    if (current_len + len < AWS_MQTT_RX_BUF_SIZE) {
        memcpy(rx_buffer + current_len, data, len);
        rx_buffer[current_len + len] = 0;
    }

    if (flags & MQTT_DATA_FLAG_LAST) {
        if (handle->command_callback != NULL) {
            handle->command_callback(rx_topic, (const uint8_t *)rx_buffer, strlen(rx_buffer));
        }
    }
}

static void mqtt_pub_request_cb(void *arg, err_t err)
{
    if (err != ERR_OK) {
    }
}
