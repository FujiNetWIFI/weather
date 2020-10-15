//
// ;*** define your project wide constants here
// 
// ;*** I like to keep memory locations at top of this file
//

GFX = $7000;
DLIST = $7F00;
DLIST2 = DLIST + $80;

FONT = $8000;
VRAM = $8400;  
VRAMTXT = VRAM + $400;
VRAM_SIZE = (41 * 40) + (9 * 80) + (9 * 40); // AA0

UTFTABLE192 = $9400;
PMG = $9000;
LOGO_CHARSET = PMG;

JSON_BUFFER = $A000;



REFRESH = 60 * 60*50;

SCROLL_SPEED = 2;
BOUNCE_DELAY = 150;

CALL_WEATHER = 0;
CALL_CHECKCITY = 1;
CALL_FORECAST = 2;

PAGE_FORECAST0 = 0;
PAGE_FORECAST1 = 1;
PAGE_WEATHER = 2;
