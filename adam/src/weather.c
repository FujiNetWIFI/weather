/**
 * Weather 
 *
 * Based on @bocianu's code
 *
 * @author Thomas Cherryhomes
 * @email thom dot cherryhomes at gmail dot com
 *
 */

#include "weather.h"
#include "options.h"
#include "location.h"
#include "screen.h"
#include "io.h"
#include "faux_json.h"

extern OptionsData optData;
extern Location locData;

void weather(void)
{
  screen_weather_init();
  
  if (!io_weather(json))
    screen_weather_could_not_get();
  
}
