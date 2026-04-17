#ifndef AWS_CONFIG_H
#define AWS_CONFIG_H

#define AWS_IOT_ENDPOINT      "YOUR_IOT_ENDPOINT.iot.REGION.amazonaws.com"
#define AWS_IOT_PORT          8883
#define AWS_DEVICE_ID         "stm32-device-001"

#define AWS_IOT_COMMAND_TOPIC     "device/" AWS_DEVICE_ID "/command"
#define AWS_IOT_RESPONSE_TOPIC    "device/" AWS_DEVICE_ID "/response"
#define AWS_IOT_TELEMETRY_TOPIC   "device/" AWS_DEVICE_ID "/telemetry"
#define AWS_IOT_LATENCY_TOPIC     "device/" AWS_DEVICE_ID "/latency"

#define AWS_CERT_PATH       "/secrets/device.pem"
#define AWS_KEY_PATH        "/secrets/device.key"
#define AWS_ROOT_CA_PATH    "/secrets/AmazonRootCA1.pem"

#define AWS_MQTT_KEEPALIVE_INTERVAL    60
#define AWS_MQTT_TIMEOUT_MS            5000
#define AWS_MQTT_TX_BUF_SIZE           512
#define AWS_MQTT_RX_BUF_SIZE           512

#endif
