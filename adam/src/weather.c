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
#include "weather.h"
#include "options.h"
#include "location.h"
#include "screen.h"
#include "io.h"
#include "faux_json.h"
#include "direction.h"
#include "icon.h"
#include "ftime.h"

extern OptionsData optData;
extern Location locData;

unsigned long dt, sunrise, sunset;

char date_txt[32];
char sunrise_txt[16];
char sunset_txt[16];
char time_txt[16];
char temp[24];
char timezone[16];
char feels_like[16];
unsigned short timezone_offset;
char pressure[14];
char humidity[16];
char dew_point[16];
char clouds[16];
char visibility[16];
char wind_speed[16];
char wind_dir[3];
char wind_txt[16];
char description[24];
unsigned char icon;

/*
  {"lat":33.1451,"lon":-97.088,"timezone":"America/Chicago","timezone_offset":-21600,"current":{"dt":1646341760,"sunrise":1646312048,"sunset":1646353604,"temp":25.42,"feels_like":24.7,"pressure":1018,"humidity":26,"dew_point":4.54,"uvi":3.66,"clouds":0,"visibility":10000,"wind_speed":5.14,"wind_deg":170,"weather":[{"id":800,"main":"Clear","description":"clear sky","icon":"01d"}]}}
 */

void weather_date(char *c, unsigned long d)
{
  Timestamp ts;

  timestamp(d,&ts);

  sprintf(c,"%u %s %u, %s",ts.day,time_month(ts.month),ts.year,time_dow(ts.dow));
}

void weather_time(char *c, unsigned long d)
{
  Timestamp ts;

  timestamp(d,&ts);

  sprintf(c,"%u:%u",ts.hour,ts.min);
}

void weather(void)
{  
  if (!io_weather(json))
    screen_weather_could_not_get();

  faux_parse_json("\"current\":{\"dt\":",0);
  dt=atol(json_part);

  faux_parse_json("\"timezone\":",0);
  strcpy(timezone,json_part);
  
  faux_parse_json("\"sunrise\":",0);
  sunrise=atol(json_part);

  faux_parse_json("\"sunrise\":",0);
  sunset=atol(json_part);

  faux_parse_json("\"temp\":",0);
  sprintf(temp,"%s*%c",json_part,optData.units == IMPERIAL ? 'F' : 'C');

  faux_parse_json("\"feels_like\":",0);
  sprintf(feels_like,"%s deg %c",json_part,optData.units == IMPERIAL ? 'F' : 'C');

  faux_parse_json("\"timezone_offset\":",0);
  timezone_offset=atoi(json_part);

  faux_parse_json("\"pressure\":",0);
  sprintf(pressure,"%s %s",json_part,optData.units == IMPERIAL ? "mPa" : "\"Hg");

  faux_parse_json("\"humidity\":",0);
  sprintf(humidity,"%s%%",json_part);

  faux_parse_json("\"dew_point\":",0);
  sprintf(dew_point,"%s deg %c",json_part,optData.units == IMPERIAL ? 'F' : 'C');
  
  faux_parse_json("\"clouds\":",0);
  sprintf(clouds,"%s%%",json_part);

  faux_parse_json("\"visibility\":",0);
  sprintf(visibility,"%d %s",atoi(json_part)/1000,optData.units == IMPERIAL ? "mi" : "km");

  faux_parse_json("\"wind_speed\":",0);
  sprintf(wind_speed,"%s %s",json_part,optData.units == IMPERIAL ? "mph" : "kph");

  faux_parse_json("\"wind_deg\":",0);
  sprintf(wind_dir,"%s",degToDirection(atoi(json_part)));

  faux_parse_json("\"description\":",0);
  sprintf(description,"%s",json_part);
  strcpy(description,strupr(description));

  faux_parse_json("\"icon\":",0);
  icon=icon_get(json_part);

  weather_date(date_txt,dt);
  weather_time(time_txt,dt);
  weather_time(sunrise_txt,sunrise);
  weather_time(sunset_txt,sunset);

  sprintf(wind_txt,"%s %s",wind_speed,wind_dir);
  
  screen_daily(date_txt,icon,temp,pressure,description,"DENTON, US",wind_txt,feels_like,dew_point,visibility,timezone,sunrise_txt,sunset_txt,humidity,clouds,time_txt,1,7,true);
}
