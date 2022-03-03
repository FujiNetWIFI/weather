/**
 * Weather 
 *
 * Based on @bocianu's code
 *
 * @author Thomas Cherryhomes
 * @email thom dot cherryhomes at gmail dot com
 *
 */

#ifndef IO_H
#define IO_H

#include <stdbool.h>
#include "options.h"

bool io_options_load(OptionsData *o);
bool io_options_save(OptionsData *o);
bool io_location_get_from_ip(char *c);
bool io_weather(char *j);

#endif /* IO_H */
