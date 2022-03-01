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

bool io_options_load(Options *o);
bool io_options_save(Options *o);
#endif /* IO_H */
