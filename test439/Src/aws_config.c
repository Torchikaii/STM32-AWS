#include "aws_config.h"

const char* aws_config_get_endpoint(void) {
    return AWS_IOT_ENDPOINT;
}

const char* aws_config_get_device_id(void) {
    return AWS_DEVICE_ID;
}

const char* aws_config_get_telemetry_topic(void) {
    return AWS_IOT_TELEMETRY_TOPIC;
}

const char* aws_config_get_command_topic(void) {
    return AWS_IOT_COMMAND_TOPIC;
}
