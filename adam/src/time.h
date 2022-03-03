/**
 * timestamp function
 *
 * Based on @bocianu's code
 *
 * @author Thomas Cherryhomes
 * @email thom dot cherryhomes at gmail dot com
 *
 */

#ifndef TIME_H
#define TIME_H

typedef struct _time
{
  unsigned short year;
  unsigned char month;
  unsigned char day;
  unsigned char hour;
  unsigned char min;
  unsigned char sec;
  unsigned char dow;
} Timestamp;

void timestamp(unsigned long t, Timestamp *ts);

#endif /* TIME_H */
