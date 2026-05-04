#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

#define configUSE_PREEMPTION            1
#define configUSE_IDLE_HOOK            1
#define configUSE_TICK_HOOK            0
#define configCPU_CLOCK_HZ            ( 168000000UL )
#define configTICK_RATE_HZ            ( 1000UL )
#define configMINIMAL_STACK_SIZE     ( 256 )
#define configMAX_PRIORITIES        ( 5 )
#define configTOTAL_HEAP_SIZE     ( 32 * 1024 )
#define configMAX_TASK_NAME_LEN     ( 16 )
#define configUSE_16_BIT_TICKS     0
#define configUSE_MUTEXES          1
#define configUSE_RECURSIVE_MUTEXES 0
#define configUSE_COUNTING_SEMAPHORES 1
#define configUSE_ALTERNATIVE_API    0
#define configQUEUE_REGISTRY_SIZE    8
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 1
#define configEXPECTED_INTERRUPT_PRIORITY 15

#define configRECORD_STACK_HIGH_ADDRESS 1

#define configUSE_TICKLESS_IDLE    0

#define configUSE_DAEMON_TASK_STARTUP_HOOK 0
#define configUSE_IDLE_TASK_SIMPLE_CORE 1

#define configENABLE_BACKWARD_COMPATIBILITY 0
#define configUSE_MINIMAL_LIST_SIZE 1
#define configUSE_QUEUE_SETS 0
#define configUSE_TIMERS 0

#define configTIMER_QUEUE_LENGTH     10
#define configTIMER_TASK_STACK_DEPTH ( configMINIMAL_STACK_SIZE * 2 )

#define configUSE_POSIX_ERRNO      0
#define configUSE_CLOCK        0

#define msgQUEUE_VALID_PEND_FUNC 0
#define configUSE_SBUF       0

#define configSTACK_DEPTH_TYPE  uint32_t
#define configIDLE_SHOULD_YIELD  1
#define configMSG_BUFFER_SIZE   0

#define configSUPPORT_STATIC_ALLOCATION 0

#define configNUM_THREAD_LOCAL_STORAGE_POINTERS 0
#define configUSE_MINIMAL_HSTACK 1
#define configUSE_TASK_NOTIFICATIONS 1

#define configTASK_NOTIFICATION_ARRAY_ENTRIES 1
#define configUSE_APPLICATION_TASK_TAG 0
#define configUSE_COUNT_SEMAPHORES 1

#define configMESSAGE_BUFFER_LENGTH_TYPE  size_t

#define configUSE_ISR_SAFE  0
#define configKERNEL_NO_VERSION     ""
#define configGENERATE_RUN_TIME_STATS 0
#define configUSE_STATS_FORMATTING_FUNCTIONS 0

#define configUSE_TRACE_FACILITY    0
#define configUSE_CO_ROUTINES     0

#define INCLUDE_vTaskDelayUntil       1
#define INCLUDE_vTaskDelete        1
#define INCLUDE_xTaskGetIdleTask  0
#define INCLUDE_xTaskGetTickCount 1
#define INCLUDE_xTaskResumeFromISR  0
#define INCLUDE_uxTaskGetStackHighWaterMark  0
#define INCLUDE_uxTaskPriorityGet 1
#define INCLUDE_vTaskPrioritySet  1
#define INCLUDE_xQueueGetMutexHolder   1

#define configMAX_SYSCALL_INTERRUPT_PRIORITY 5
#define configMAX_API_CALL_INTERRUPT_PRIORITY 4

#define configLITTLE_ENDIAN    1
#define configMAX_CO_OROUTINES 0

#define configUSE_TCP 1

#define ipconfigUSE_NETWORK_STATE_EVENT  0
#define ipconfigUSE_NOTIFY  0

#define configNETWORK_BYTES_TO_SEND    1000
#define configNETWORK_BUFFER_PAYLOAD_SIZE ( 1536 )
#define configNETWORK_ETH_RAM_ADDR   ( 0x20000000 )

#include <stdint.h>
extern uint32_t SystemCoreClock;
#define configCPU_CLOCK_HZ SystemCoreClock

typedef uint32_t TickType_t;
#define pdMS_TO_TICKS( ms ) ( ( TickType_t ) ( ( ( uint64_t ) ( ms ) * configTICK_RATE_HZ + 999U ) / 1000U )

#define portMAX_DELAY ( TickType_t ) 0xffffffffUL
#define portTICK_PERIOD_MS ( 1000UL / configTICK_RATE_HZ )

#endif