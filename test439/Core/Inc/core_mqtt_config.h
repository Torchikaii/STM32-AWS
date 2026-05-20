#ifndef CORE_MQTT_CONFIG_H
#define CORE_MQTT_CONFIG_H

#include <stdio.h>

#define MQTT_STATE_ARRAY_SIZE            128
#define MQTT_MAX_CONCURRENT_OPERATIONS   1

#define LogError( x )  printf x
#define LogWarn( x )   printf x
#define LogInfo( x )   printf x
#define LogDebug( x )

#endif
