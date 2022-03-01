/**
 * Weather 
 *
 * Based on @bocianu's code
 *
 * @author Thomas Cherryhomes
 * @email thom dot cherryhomes at gmail dot com
 *
 */

#include <eos.h>
#include <string.h>
#include "io.h"
#include "constants.h"

#define FUJI_DEV 0x0F

static unsigned char response[1024];

bool io_options_load(Options *o)
{
  bool ret;
  struct
  {
    unsigned char cmd;
    unsigned short creator;
    unsigned char app;
    unsigned char key;
  } ak;
  
  ak.cmd = 0xDD;
  ak.creator = APPKEY_CREATOR_ID;
  ak.app = APPKEY_APP_ID;
  ak.key = APPKEY_CONFIG_KEY;
  
  eos_write_character_device(FUJI_DEV,ak,sizeof(ak));
  if (eos_read_character_device(FUJI_DEV,response,1024) == 0x80)
    {
      memcpy(o,response,sizeof(Options));
      ret=true;
    }
  else
    ret=false;

  return ret;								 
}  

bool io_options_save(Options *o)
{
  bool ret;
  struct
  {
    unsigned char cmd;
    unsigned short creator;
    unsigned char app;
    unsigned char key;
    char data[64];
  } ak;

  ak.cmd = 0xDE;
  ak.creator = APPKEY_CREATOR_ID;
  ak.app = APPKEY_APP_ID;
  ak.key = APPKEY_CONFIG_KEY;
  memcpy(ak.data,o,sizeof(Options));

  return eos_write_character_device(FUJI_DEV,ak,sizeof(ak)) == 0x80;
}
