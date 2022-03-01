/**
 * Weather 
 *
 * Based on @bocianu's code
 *
 * @author Thomas Cherryhomes
 * @email thom dot cherryhomes at gmail dot com
 *
 */

#include <stdbool.h>
#include "options.h"
#include "screen.h"
#include "io.h"

bool options_load(void)
{
  return io_options_load(&options);
}

void options_defaults(void)
{
  Options o;
  screen_options_init_not_found();

  memset(o.apiKeyOW,0,sizeof(o.apiKeyOW));
  o.refreshInterval=DEFAULT_REFRESH;
}

void options_init(void)
{
  screen_options_init();

  if (!options_load())
    options_defaults();
}

void options(void)
{
  options_init();
}
