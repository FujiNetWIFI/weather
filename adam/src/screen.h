/**
 * Weather
 *
 * Screen routines
 */

#ifndef SCREEN_H
#define SCREEN_H

#include <stdbool.h>

void screen_init(void);

void screen_welcome(void);

void screen_daily(char *date,
		  unsigned char icon,
		  char *temperature,
		  char *pressure,
		  char *description,
		  char *location,
		  char *wind,
		  char *feels,
		  char *dew,
		  char *visibility,
		  char *timezone,
		  char *sunrise,
		  char *sunset,
		  char *humidity,
		  char *clouds,
		  char *time,
		  unsigned char foregroundColor,
		  unsigned char backgroundColor,
		  bool dn);

void screen_options_init(void);
void screen_options_init_not_found(void);


#endif /* SCREEN_H */
