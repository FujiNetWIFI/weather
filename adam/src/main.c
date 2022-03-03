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
#include "init.h"
#include "welcome.h"
#include "options.h"
#include "location.h"
#include "weather.h"

void main(void)
{
  init();
  welcome();
  options();
  location();
  weather();
}
