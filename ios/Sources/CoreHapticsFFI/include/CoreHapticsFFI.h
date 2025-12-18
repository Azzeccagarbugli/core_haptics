#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* CHFFIEngineHandle;
typedef void* CHFFIPatternHandle;
typedef void* CHFFIPlayerHandle;

typedef void (*CHFFIEngineCallback)(int32_t eventCode, const char* message, void* context);

enum {
  CHFFI_ERROR_OK = 0,
  CHFFI_ERROR_NOT_SUPPORTED = 1,
  CHFFI_ERROR_ENGINE = 2,
  CHFFI_ERROR_INVALID_HANDLE = 3,
  CHFFI_ERROR_INVALID_ARGUMENT = 4,
  CHFFI_ERROR_PATTERN = 5,
  CHFFI_ERROR_PLAYER = 6,
  CHFFI_ERROR_IO = 7,
  CHFFI_ERROR_DECODE = 8,
  CHFFI_ERROR_RUNTIME = 9,
  CHFFI_ERROR_UNKNOWN = 255
};

enum {
  CHFFI_EVENT_ENGINE_STOPPED = 1,
  CHFFI_EVENT_ENGINE_RESET = 2,
  CHFFI_EVENT_ENGINE_INTERRUPTED = 3,
  CHFFI_EVENT_ENGINE_RESTARTED = 4
};

int32_t chffi_string_free(const char* message);

int32_t chffi_engine_create(CHFFIEngineHandle* outHandle,
                            CHFFIEngineCallback callback,
                            void* context,
                            char** message);
int32_t chffi_engine_start(CHFFIEngineHandle handle, char** message);
int32_t chffi_engine_stop(CHFFIEngineHandle handle, char** message);
void chffi_engine_release(CHFFIEngineHandle handle);

int32_t chffi_pattern_from_ahap_data(const uint8_t* bytes,
                                     int32_t length,
                                     CHFFIPatternHandle* outPattern,
                                     char** message);
int32_t chffi_pattern_from_ahap_file(const char* path,
                                     CHFFIPatternHandle* outPattern,
                                     char** message);
void chffi_pattern_release(CHFFIPatternHandle handle);

int32_t chffi_player_create(CHFFIEngineHandle engine,
                            CHFFIPatternHandle pattern,
                            CHFFIPlayerHandle* outPlayer,
                            char** message);
int32_t chffi_player_play(CHFFIPlayerHandle player, double atTime, char** message);
int32_t chffi_player_stop(CHFFIPlayerHandle player, double atTime, char** message);
int32_t chffi_player_set_loop(CHFFIPlayerHandle player,
                              int32_t enabled,
                              double loopStart,
                              double loopEnd,
                              char** message);
int32_t chffi_player_send_parameter(CHFFIPlayerHandle player,
                                    int32_t parameterId,
                                    double value,
                                    double atTime,
                                    char** message);
void chffi_player_release(CHFFIPlayerHandle player);

int32_t chffi_supports_haptics(void);

void chffi_impact_light(void);
void chffi_impact_medium(void);
void chffi_impact_heavy(void);
void chffi_impact_soft(void);
void chffi_impact_rigid(void);

void chffi_notification_success(void);
void chffi_notification_warning(void);
void chffi_notification_error(void);

void chffi_selection(void);

#ifdef __cplusplus
}  // extern "C"
#endif

