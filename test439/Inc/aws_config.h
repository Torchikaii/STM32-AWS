#ifndef AWS_CONFIG_H
#define AWS_CONFIG_H

// CRITICAL: AWS IoT Core Rate Limiting
// AWS charges per message. Uncontrolled publish causes massive bills.
// Minimum 30 seconds between telemetry recommended.

#define TELEMETRY_PUBLISH_INTERVAL_MS  300000  // 5 minutes (288 messages/day)
#define MQTT_KEEPALIVE_INTERVAL_SEC   600     // 10 minutes (reduce connection overhead)

#define AWS_IOT_ENDPOINT       "YOUR_ENDPOINT.iot.REGION.amazonaws.com"
#define AWS_IOT_PORT           8883
#define AWS_DEVICE_ID          "stm32-device-001"

#define AWS_IOT_COMMAND_TOPIC     "device/" AWS_DEVICE_ID "/command"
#define AWS_IOT_RESPONSE_TOPIC   "device/" AWS_DEVICE_ID "/response"
#define AWS_IOT_TELEMETRY_TOPIC   "device/" AWS_DEVICE_ID "/telemetry"
#define AWS_IOT_LATENCY_TOPIC    "device/" AWS_DEVICE_ID "/latency"

#define AWS_CERT_PATH         "/secrets/device.pem"
#define AWS_KEY_PATH         "/secrets/device.key"
#define AWS_ROOT_CA_PATH    "/secrets/AmazonRootCA1.pem"

#define MQTT_AGENT_TASK_STACK_SIZE    4096
#define MQTT_AGENT_TASK_PRIORITY   5
#define MQTT_RECEIVE_BUFFER_SIZE   1024
#define MQTT_TRANSMIT_BUFFER_SIZE  1024

#endif