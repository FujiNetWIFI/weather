/**
 * Weather 
 *
 * Based on @bocianu's code
 *
 * @author Thomas Cherryhomes
 * @email thom dot cherryhomes at gmail dot com
 *
 */

#ifndef OPTIONS_H
#define OPTIONS_H

#include <stdbool.h>

typedef enum _units
  {
   METRIC,
IMPERIAL,
   UNKNOWN
  } Units;

typedef struct _optionsdata
{
  char apiKeyOW[32];
  unsigned char refreshInterval;
  Units units;
  bool showRegion;
  bool detectLocation;
  char theme[12];
  unsigned char maxPrecision;
  char unused[10];
} OptionsData;

typedef struct _location
{
  char city[41];
  char region_code[3];
  char country_code[3];
  char latitude[8];
  char longitude[8];
} Location;

void options_save(OptionsData *o);
void options(void);

#endif /* OPTIONS_H */
