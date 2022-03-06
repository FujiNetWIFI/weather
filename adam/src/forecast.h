/**
 * Weather 
 *
 * Based on @bocianu's code
 *
 * @author Thomas Cherryhomes
 * @email thom dot cherryhomes at gmail dot com
 *
 */

#ifndef FORECAST_H
#define FORECAST_H

typedef struct
{
  char date[8];
  unsigned char icon;
  char dow[4];
  char hi[8];
  char lo[8];
  char pressure[10];
  char wind[8];
  char dir[8];
  char rain[12];
  char snow[12];
  char pop[8];
} ForecastData;

void forecast(void);

#endif /* FORECAST_H */
