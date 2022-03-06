/**
 * Weather 
 *
 * Based on @bocianu's code
 *
 * @author Thomas Cherryhomes
 * @email thom dot cherryhomes at gmail dot com
 *
 */

#include <conio.h>
#include "options.h"
#include "location.h"
#include "screen.h"
#include "io.h"
#include "faux_json.h"
#include "direction.h"
#include "icon.h"
#include "ftime.h"
#include "input.h"

unsigned char forecast_offset;
ForecastData forecastData;

extern OptionsData optData;

void forecast_parse(unsigned char i, ForecastData *f)
{
  Timestamp ts;
  faux_parse_json("\"dt\":",i);

  timestamp(atol(json_part),&ts);
  snprintf(f->date,8,"%d %s",ts.day,time_month(ts.month));
  snprintf(f->dow,4,"%s",time_dow(ts.dow));
  
  faux_parse_json("\"icon\":",i);
  f->icon=atoi(json_part);

  faux_parse_json("\"min\":",i);
  snprintf(f->lo,8,"%s",json_part);

  faux_parse_json("\"max\":",i);
  snprintf(f->hi,8,"%s",json_part);

  faux_parse_json("\"pressure\":",i);
  snprintf(f->pressure,10,"%s",json_part);

  faux_parse_json("\"wind_speed\":",i);
  snprintf(f->wind,8,"%s %s",json_part,optData.units == IMPERIAL ? "mph" : "kph");

  faux_parse_json("\"wind_deg\":",i);
  snprintf(f->dir,8,"%s",degToDirection(atoi(json_part)));

  faux_parse_json("\"pop\"",i);
  snprintf(f->pop,8,"%s",json_part);

  faux_parse_json("\"rain\":",i);
  snprintf(f->rain,8,"%s",json_part);
  
  faux_parse_json("\"snow\":",i);
  snprintf(f->snow,8,"%s",json_part);
}

void forecast(void)
{
  if (!io_forecast(json))
    screen_weather_could_not_get();

  screen_forecast_init();
  
  for (int i=0;i<4;i++)
    {
      forecast_parse(forecast_offset+i,&forecastData);
      screen_forecast(i,&forecastData);
    }
  
  while(1);
}
