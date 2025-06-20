#ifndef ESP_APP_DESC_H
#define ESP_APP_DESC_H

#ifdef __cplusplus
extern "C" {
#endif

    // Declare the app descriptor as a function that returns its address
    // This matches the @_silgen_name approach in Swift
    void* esp_app_desc(void);

#ifdef __cplusplus
}
#endif

#endif // ESP_APP_DESC_H