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
#include <eos.h>
#include <string.h>
#include <conio.h>
#include "constants.h"
#include "io.h"
#include "options.h"

#define NET_DEV  0x09
#define FUJI_DEV 0x0F

#define READ_WRITE 12

extern OptionsData optData;
extern Location locData;

static unsigned char response[1024];
static char line[256];

bool io_options_load(OptionsData *o)
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
      DCB *dcb = eos_find_dcb(FUJI_DEV);

      if (dcb->len == 1)
	return false;
      
      memcpy(o,response,sizeof(OptionsData));
      ret=true;
    }
  else
    ret=false;

  return ret;								 
}  

bool io_options_save(OptionsData *o)
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
  memcpy(ak.data,o,sizeof(OptionsData));

  return eos_write_character_device(FUJI_DEV,ak,sizeof(ak)) == 0x80;
}

bool io_location_get_from_ip(char *c)
{
  unsigned char res;
  char cc='C';
  
  struct
  {
    unsigned char cmd;
    unsigned char aux1;
    unsigned char aux2;
    unsigned char url[160];
  } co;

  // Set up open
  memset(co,0,sizeof(co));
  co.cmd = 'O';
  co.aux1 = READ_WRITE;
  co.aux2 = 0;
  strcpy(co.url,"N:HTTP://");
  strcat(co.url,IP_API);
  strcat(co.url,"/check?access_key=9ba846d99b9d24288378762533e00318&fields=ip,region_code,country_code,city,latitude,longitude");

  // Do open
  res = eos_write_character_device(NET_DEV,co,sizeof(co));
  
  if (res != 0x80)
      return false; // error

  while ((res = eos_read_character_device(NET_DEV,response,1024)) == 0x80)
    {
      strcat(line,response);
      memset(response,0,sizeof(response));
    }
  
  strcpy(c,line);

  // Close connection
  eos_write_character_device(NET_DEV,&cc,1);
}

bool io_weather(char *j)
{
  char units[14];
  unsigned char res;
  struct
  {
    char cmd;
    char aux1;
    char aux2;
    char url[255];
  } co;

  if (optData.units == METRIC)
    strcpy(units,"metric");
  else if (optData.units == IMPERIAL)
    strcpy(units,"imperial");

  // Set up open 
  co.cmd='O';
  co.aux1=READ_WRITE;
  co.aux2=0;
  snprintf(co.url,sizeof(co.url),"N:HTTP://%s//data/2.5/onecall?lat=%s&lon=%s&exclude=minutely,hourly,alerts,daily&units=%s&appid=%s",OW_API,locData.latitude,locData.longitude,units,optData.apiKeyOW);

  // Do open
  res=eos_write_character_device(NET_DEV,co,sizeof(co));

  if (res != 0x80)
    return false;

  // Get body
  while ((res = eos_read_character_device(NET_DEV,response,1024)) == 0x80)
    {
      strcat(line,response);
      memset(response,0,sizeof(response));
    }

  strcpy(j,line);

  // Close connection
  eos_write_character_device(NET_DEV,'C',1);
  
  return true;
}
