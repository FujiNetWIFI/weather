/**
 * Weather
 *
 * Screen Routines
 */

#include <msx.h>
#include <eos.h>
#include <smartkeys.h>
#include <conio.h>
#include <sys/ioctl.h>
#include <stdbool.h>
#include "screen.h"

char tmp[192]; // Temporary for screen formatting

const unsigned char spritedata[]=
  {
   // 0 Sunny
   0x04,0x44,0x20,0x07,0x0F,0x1F,0x1F,0x1F,0xDF,0x1F,0x1F,0x0F,0x07,0x20,0x44,0x04,0x20,0x22,0x04,0xE0,0xF0,0xF8,0xF8,0xF8,0xFB,0xF8,0xF8,0xF0,0xE0,0x04,0x22,0x20,
   
   // 1 Half Sunny
   0x04,0x44,0x20,0x07,0x0F,0x9F,0x5F,0x1F,0x1F,0x1F,0x1F,0x0F,0x07,0x00,0x00,0x00,0x20,0x22,0x04,0xE0,0xF1,0xFA,0xF8,0xF8,0xF8,0xF8,0xF8,0xF0,0xE0,0x00,0x00,0x00,

   // 2 Cloud 1
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x07,0x6F,0xFF,0xFF,0xFF,0x7F,0x1F,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0xCC,0xFE,0xFF,0xFF,0xFF,0xFE,0xF8,0xF0,

   // 3 Cloud 2
   0x00,0x00,0x00,0x03,0x07,0x6F,0xFF,0xFF,0xFF,0x7F,0x1F,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0xCC,0xFE,0xFF,0xFF,0xFF,0xFE,0xF8,0xF0,0x00,0x00,0x00,0x00,

   // 4 Cloud 3
   0x00,0x00,0x03,0x07,0x6F,0xFF,0xFF,0xFF,0x7F,0x1F,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0xCC,0xFE,0xFF,0xFF,0xFF,0xFE,0xF8,0xF0,0x00,0x00,0x00,0x00,0x00,

   // 5 Cloud 4
   0x03,0x07,0x6F,0xFF,0xFF,0xFF,0x7F,0x1F,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0xCC,0xFE,0xFF,0xFF,0xFF,0xFE,0xF8,0xF0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

   // 6 Mist 1
   0x05,0x00,0x20,0x00,0x40,0x00,0x80,0x00,0x20,0x00,0x40,0x00,0x10,0x00,0x0B,0x00,0xB4,0x00,0x08,0x00,0x02,0x00,0x01,0x00,0x02,0x00,0x01,0x00,0x02,0x00,0x68,0x00,

   // 7 Mist 2
   0x00,0x00,0x0D,0x00,0x1B,0x00,0x37,0x00,0x2F,0x00,0x1B,0x00,0x06,0x00,0x00,0x00,0x00,0x00,0xE0,0x00,0xD8,0x00,0xEC,0x00,0xD8,0x00,0xEC,0x00,0xD0,0x00,0x00,0x00,

   // 8 Moon
   0x03,0x0F,0x1F,0x3F,0x3E,0x7E,0x7C,0x7C,0x7C,0x7C,0x7E,0x3E,0x3F,0x1F,0x0F,0x03,0xE0,0xF0,0xFC,0x84,0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x84,0xFC,0xF0,0xE0,

   // 9 Cloud 5
   0x03,0x07,0x6F,0xFF,0xFF,0xFF,0x7F,0x1F,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0xCC,0xFE,0xFF,0xFF,0xFF,0xFE,0xF8,0xF0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

   // A Cloud 6
   0x03,0x07,0x6F,0xFF,0xFF,0xFF,0x7F,0x1F,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x80,0xCC,0xFE,0xFF,0xFF,0xFF,0xFE,0xF8,0xF0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

   // B Lightning 1
   0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x03,0x06,0x0F,0x00,0x00,0x01,0x07,0x03,0x02,0x00,0x00,0x00,0x00,0x00,0xC0,0x80,0x00,0x00,0xF0,0x60,0xC0,0x80,0xC0,0x80,0x00,

   // C Lightning 2
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x03,0x07,0x00,0x00,0x00,0x03,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x60,0xC0,0x80,0x00,0xF8,0x30,0x60,0xC0,0xE0,0xC0,0x00,

   // D Rain 1
   0x00,0x00,0x00,0x00,0x08,0x0A,0x02,0x10,0x14,0x05,0x21,0x28,0x0A,0x42,0x50,0x14,0x00,0x00,0x00,0x00,0x00,0x04,0x84,0xA0,0x2A,0x0A,0x40,0x54,0x14,0x80,0xA8,0x20,

   // E Rain 2
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x05,0x21,0x28,0x0A,0x42,0x50,0x14,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x08,0x41,0x55,0x14,0x80,0xAA,0x22,

   // F Snow 1
   0x00,0x00,0x00,0x00,0x00,0x00,0x24,0x0A,0x04,0x20,0x51,0x20,0x00,0x44,0xE0,0x40,0x00,0x00,0x00,0x80,0x00,0x20,0x50,0x22,0x05,0x92,0x40,0x90,0x00,0x4A,0xE0,0x44,

   // 10 Snow 2
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x00,0x24,0x80,0x15,0x4A,0xA4,0x49,0x00,0x00,0x00,0x00,0x00,0x00,0x20,0x00,0x02,0x00,0x84,0x01,0x12,0x45,0xA2,0x48,

   // 11 Lightning 3
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x03,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x30,0x60,0xC0,0x80,0xFC,0x18,0x30,0x60,0xF0,0xE0,0x80,   
  };

const unsigned char udgs[]=
  {
   // Digits 0-9 as 16x16 chars
   0x03,0x0F,0x0C,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x0C,0x0F,0x03,0xC0,0xF0,0x30,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x30,0xF0,0xC0,
   0x01,0x03,0x07,0x07,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x07,0x07,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0x80,0xE0,0xE0,
   0x03,0x0F,0x0C,0x18,0x18,0x00,0x00,0x00,0x01,0x03,0x07,0x0E,0x1C,0x18,0x1F,0x1F,0xC0,0xF0,0x30,0x18,0x18,0x38,0x70,0xE0,0xC0,0x80,0x00,0x00,0x00,0x00,0xF8,0xF8,
   0x03,0x0F,0x0C,0x18,0x18,0x00,0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x0C,0x0F,0x03,0xC0,0xF0,0x30,0x18,0x18,0x18,0x30,0xE0,0xE0,0x30,0x18,0x18,0x18,0x30,0xF0,0xC0,
   0x01,0x01,0x03,0x03,0x06,0x06,0x0C,0x0C,0x18,0x18,0x3F,0x3F,0x00,0x00,0x00,0x00,0xC0,0xC0,0xC0,0xC0,0xC0,0xC0,0xC0,0xC0,0xC0,0xC0,0xF0,0xF0,0xC0,0xC0,0xC0,0xC0,
   0x1F,0x1F,0x18,0x18,0x18,0x18,0x1B,0x1F,0x1C,0x00,0x00,0x18,0x18,0x0C,0x0F,0x03,0xF8,0xF8,0x00,0x00,0x00,0x00,0xC0,0xF0,0x30,0x18,0x18,0x18,0x18,0x30,0xF0,0xC0,
   0x03,0x0F,0x0C,0x18,0x18,0x18,0x1B,0x1F,0x1C,0x18,0x18,0x18,0x18,0x0C,0x0F,0x03,0xC0,0xF0,0x30,0x18,0x18,0x00,0xC0,0xF0,0x30,0x18,0x18,0x18,0x18,0x30,0xF0,0xC0,
   0x0F,0x0F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x01,0x01,0x03,0x03,0x03,0xF8,0xF8,0x30,0x30,0x60,0x60,0x60,0xC0,0xC0,0xC0,0x80,0x80,0x80,0x00,0x00,0x00,
   0x03,0x0F,0x0C,0x18,0x18,0x18,0x0C,0x07,0x07,0x0C,0x18,0x18,0x18,0x0C,0x0F,0x03,0xC0,0xF0,0x30,0x18,0x18,0x18,0x30,0xE0,0xE0,0x30,0x18,0x18,0x18,0x30,0xF0,0xC0,
   0x03,0x0F,0x0C,0x18,0x18,0x18,0x18,0x1C,0x0F,0x03,0x00,0x18,0x18,0x0C,0x0F,0x03,0xC0,0xF0,0x30,0x18,0x18,0x18,0x18,0x38,0xF8,0xD8,0x18,0x18,0x18,0x30,0xF0,0xC0,

   // Degree symbol
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x18,0x3C,0x66,0x66,0x3C,0x18,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

   // Negative symbol
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7C,0x7C,0x00,0x00,0x00,0x00,0x00,0x00,

   // . symbol
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x38,0x38,0x38,

   // FARENHEIT
   0x1F,0x1F,0x18,0x18,0x18,0x18,0x18,0x1F,0x1F,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0xF8,0xF8,0x00,0x00,0x00,0x00,0x00,0xC0,0xC0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,

   // CELSIUS
   0x03,0x0F,0x0C,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x0C,0x0F,0x03,0xC0,0xF0,0x30,0x18,0x18,0x00,0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x30,0xF0,0xC0,
  };

const char logo_udgs[] =
  {
   0xff, 0xff, 0xc0, 0xc0, 0xc0, 0xc0, 0xff, 0xff, 0x18, 0x18, 0x18, 0x18,
   0x18, 0x18, 0x18, 0x18, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06,
   0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x18, 0x18, 0x18, 0x18,
   0x18, 0x19, 0x1b, 0x19, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0x00,
   0x18, 0x18, 0x1c, 0x0c, 0x0f, 0x07, 0x01, 0x00, 0x06, 0x06, 0x0e, 0x0c,
   0x3c, 0xf8, 0xe0, 0x00, 0x03, 0x03, 0x03, 0x43, 0xe7, 0x7e, 0x3c, 0x00,
   0x19, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x08, 0x0c, 0x0e, 0x0f,
   0x0f, 0x0d, 0x8c, 0x0c, 0x01, 0x01, 0x01, 0x01, 0x81, 0xc1, 0xe1, 0x71,
   0x8f, 0x8f, 0x8c, 0x8c, 0x8c, 0x8c, 0x8f, 0x8f, 0xf3, 0xf3, 0x00, 0x00,
   0x00, 0x00, 0xf0, 0xf0, 0xff, 0xff, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
   0x0c, 0x0c, 0x0c, 0x0c, 0x0c, 0xcc, 0x0c, 0x00, 0x39, 0x1d, 0x0f, 0x07,
   0x03, 0x01, 0x00, 0x00, 0x8c, 0x8c, 0x8c, 0x8c, 0x8c, 0x8f, 0x8f, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xf0, 0x00, 0x30, 0x30, 0x30, 0x30,
   0x30, 0x30, 0x30, 0x00, 0x04, 0x04, 0x04, 0x0e, 0x1f, 0x3f, 0xff, 0x3f,
   0x7f, 0x3e, 0x1c, 0x1c, 0x22, 0xc1, 0xc1, 0xc1, 0x10, 0x10, 0x10, 0x38,
   0x7c, 0xfe, 0xff, 0xfe, 0x1f, 0x0e, 0x04, 0x04, 0x04, 0x1f, 0x04, 0x04,
   0x22, 0x1c, 0x08, 0x08, 0x08, 0xff, 0x08, 0x08, 0x7c, 0x38, 0x38, 0x7c,
   0xfe, 0xff, 0xfe, 0x7c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x04, 0x1f,
   0x00, 0x08, 0x08, 0x08, 0x1c, 0x3e, 0x7f, 0xff, 0x00, 0x00, 0x00, 0x00,
   0x10, 0x10, 0x10, 0xfe, 0x08, 0x08, 0x08, 0x1f, 0x08, 0x00, 0x00, 0x00,
   0x38, 0x10, 0x10, 0xff, 0x10, 0x10, 0x10, 0x00, 0x10, 0x10, 0x10, 0xfc,
   0x10, 0x10, 0x00, 0x00
  };

void screen_init(void)
{
  void *param = &udgs;

  clrscr();
}

void screen_bigprint_offsets(char *c, unsigned char *c0, unsigned char *c1, unsigned char *c2, unsigned char *c3)
{
  // 0 2 1 3
  unsigned char o=0x80; // Initial char offset
  char t = *c;
  
  switch(t)
    {
    case '*':
      o+=0x28;
      break;
    case '-':
      o+=0x2C;
      break;
    case '.':
      o+=0x30;
      break;
    case 'F':
      o+=0x34;
      break;
    case 'C':
      o+=0x38;
      break;
    default:
      t -= 0x30;
      t *= 4;
      t += 0x80;
      o=t;
      break;
    }

  *c0=o;
  *c1=o+2;
  *c2=o+1;
  *c3=o+3;
}

void screen_bigprint(unsigned char x,unsigned char y,char *c)
{
  x <<= 2;
  y <<= 2;

  while (*c != 0x00)
    {
      unsigned char c0,c1,c2,c3;
      
      screen_bigprint_offsets(c,&c0,&c1,&c2,&c3);
      if ((*c == '.') || (*c == '*'))
	{
	  gotoxy(x,y  ); cprintf("%c",c1);
	  gotoxy(x,y+1); cprintf("%c",c3);
	  x += 1;	  
	}
      else
	{
	  gotoxy(x,y  ); cprintf("%c%c",c0,c1);
	  gotoxy(x,y+1); cprintf("%c%c",c2,c3);
	  x += 2;
	}
      c++;
    }
}

void screen_icon(unsigned char i, bool d)
{
  switch(i)
    {
    case 0: // clear sky
      // Sun with clouds
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,d == true ? 0x00 : 32);
      msx_vpoke(0x1b03,0x0A);
      break;
    case 1: // few clouds
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,0x08);
      msx_vpoke(0x1b03,0x0F);

      msx_vpoke(0x1b04,0x20);
      msx_vpoke(0x1b05,0x08);
      msx_vpoke(0x1b06,d == true ? 0x04 : 32);
      msx_vpoke(0x1b07,0x0A);
      break;
    case 2: // Scattered clouds
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,0x10);
      msx_vpoke(0x1b03,0x0F);
      break;
    case 3: // broken clouds
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,16);
      msx_vpoke(0x1b03,0x0e);

      msx_vpoke(0x1b04,0x20);
      msx_vpoke(0x1b05,0x08);
      msx_vpoke(0x1b06,20);
      msx_vpoke(0x1b07,0x01);      
      break;
    case 4: // shower rain
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,56);
      msx_vpoke(0x1b03,0x04);

      if (d == true)
	{
	  msx_vpoke(0x1b04,0x20);
	  msx_vpoke(0x1b05,0x08);
	  msx_vpoke(0x1b06,16);
	  msx_vpoke(0x1b07,0x0e);
	  
	  msx_vpoke(0x1b08,0x20);
	  msx_vpoke(0x1b09,0x08);
	  msx_vpoke(0x1b0a,20);
	  msx_vpoke(0x1b0b,0x01);
	}
      else
	{
	  msx_vpoke(0x1b04,0x20);
	  msx_vpoke(0x1b05,0x08);
	  msx_vpoke(0x1b06,0x08);
	  msx_vpoke(0x1b07,0x0F);
	  
	  msx_vpoke(0x1b08,0x20);
	  msx_vpoke(0x1b09,0x08);
	  msx_vpoke(0x1b0a,d == true ? 0x04 : 32);
	  msx_vpoke(0x1b0b,0x0A);
	}
      break;
    case 5: // rain
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,56);
      msx_vpoke(0x1b03,0x04);

      msx_vpoke(0x1b04,0x20);
      msx_vpoke(0x1b05,0x08);
      msx_vpoke(0x1b06,8);
      msx_vpoke(0x1b07,0x0F);

      msx_vpoke(0x1b08,0x20);
      msx_vpoke(0x1b09,0x08);
      msx_vpoke(0x1b0a,4);
      msx_vpoke(0x1b0b,0x0A);
      break;
    case 6: // thunderstorm
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,48);
      msx_vpoke(0x1b03,0x0A);
      
      msx_vpoke(0x1b04,0x20);
      msx_vpoke(0x1b05,0x08);
      msx_vpoke(0x1b06,16);
      msx_vpoke(0x1b07,0x0e);

      msx_vpoke(0x1b08,0x20);
      msx_vpoke(0x1b09,0x08);
      msx_vpoke(0x1b0a,20);
      msx_vpoke(0x1b0b,0x01);      

      msx_vpoke(0x1b0c,0x20);
      msx_vpoke(0x1b0d,0x08);
      msx_vpoke(0x1b0e,56);
      msx_vpoke(0x1b0f,0x04);
      break;

    case 7: // snow
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,60);
      msx_vpoke(0x1b03,0x0e);
      
      msx_vpoke(0x1b04,0x20);
      msx_vpoke(0x1b05,0x08);
      msx_vpoke(0x1b06,16);
      msx_vpoke(0x1b07,0x0f);

      msx_vpoke(0x1b08,0x20);
      msx_vpoke(0x1b09,0x08);
      msx_vpoke(0x1b0a,20);
      msx_vpoke(0x1b0b,0x01);      

    case 8: // mist
      msx_vpoke(0x1b00,0x20);
      msx_vpoke(0x1b01,0x08);
      msx_vpoke(0x1b02,28);
      msx_vpoke(0x1b03,0x0f);
      
      msx_vpoke(0x1b04,0x20);
      msx_vpoke(0x1b05,0x08);
      msx_vpoke(0x1b06,24);
      msx_vpoke(0x1b07,0x0e);
      break;
    }
}

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
		  bool dn)
{
  msx_color(15,1,1);
  clrscr();
  smartkeys_display(NULL,NULL,"LOCATION","  SHOW\nFORECAST","  SHOW\n CELSIUS"," REFRESH");
  smartkeys_status("\n  DAILY VIEW");

  msx_color(foregroundColor,backgroundColor,backgroundColor);
  
  gotoxy(8,0); cprintf("%s",date);  
  screen_icon(icon,false);
  screen_bigprint(2,1,temperature);
  gotoxy(23,4); cprintf("%s",pressure);
  gotoxy(13,7); cprintf("%s",description);
  gotoxy(12,9); cprintf("%s",location);

  sprintf(tmp,"WIND: 10.36 MPH N\nFEELS LIKE: %s\n\nDEW POINT: %s\nVISIBILITY: %s\n\nTIME ZONE: %s",wind,feels,dew,visibility,timezone);
  smartkeys_puts(0,96,tmp);

  sprintf(tmp,"SUNRISE: %s\nSUNSET: %s\n\nHUMIDITY: %s\nCLOUDS: %s\n\nTIME: %s",sunrise,sunset,humidity,clouds,time);
  smartkeys_puts(160,96,tmp);
}

void screen_welcome(void)
{
    void *param = &logo_udgs;

  console_ioctl(IOCTL_GENCON_SET_UDGS,&param);
  smartkeys_set_mode();
  
  printf("\x20\x20\x20\x20\x20\x9A\x9B\x9C\x20\x20\x20\x20\x20       OPEN WEATHER");
  printf("\x80\x81\x82\x83\x84\x94\x95\x96\x8A\x8B\x8C\x8D\x8e          CLIENT\n");
  printf("\x85\x86\x87\x88\x89\x97\x98\x99\x8F\x90\x91\x92\x93           for\n");
  printf("\x20\x20\x20\x20\x20\x20\x9D\x9E\x9F\x20\x20\x20\x20       COLECO  ADAM\n");  
}

void screen_options_init(void)
{
  smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
  smartkeys_status("\n  INITIALIZING OPTIONS...");
}

void screen_options_init_not_found(void)
{
  smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
  smartkeys_status("\n  NO OPTIONS FOUND, USING DEFAULTS.");
}

void screen_options_could_not_save(void)
{
  smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
  smartkeys_status("\n  COULD NOT SAVE OPTIONS.");
}

void screen_location_detect(void)
{
  smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
  smartkeys_status("\n  DETECTING YOUR LOCATION...");
}

void screen_weather_init(void)
{
  void param = &udgs;
  console_ioctl(IOCTL_GENCON_SET_UDGS,&param);

  eos_write_vdp_register(1,0xE3);
  msx_vwrite(spritedata,0x3800,sizeof(spritedata));

  clrscr();

  smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
  smartkeys_status("\n  RETRIEVING WEATHER INFORMATION...");
}

void screen_weather_could_not_get()
{
  smartkeys_display(NULL,NULL,NULL,NULL,NULL,NULL);
  smartkeys_status("\n  COULD NOT RETRIEVE WEATHER DATA.");
}
