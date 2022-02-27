/* Output from p2c 2.00.Oct.15, the Pascal-to-C translator */
/* From input file "weather.pas" */


#include <p2c/p2c.h>


/*$librarypath '../blibs/'*/
main(argc, argv)
int argc;
Char *argv[];
{
  boolean fin = false;
  long second, minute, hour, day;
  long year = 1970, dow = 4;
  boolean leap;
  long daysInYear, month, dim;

/* p2c: weather.pas, line 3: Warning: Expected BEGIN, found a '/' [227] */
  /*$r resources.rc*/






  PASCAL_MAIN(argc, argv);








/* p2c: datetime.inc, line 18: Warning: Symbol 'FIN' is not defined [221] */
  second = ux;
/* p2c: datetime.inc, line 19: Warning: Symbol 'UX' is not defined [221] */
/* p2c: datetime.inc, line 19:
 * Warning: Symbol 'SECOND' is not defined [221] */
  minute = ux / 60;
/* p2c: datetime.inc, line 20: Warning: Symbol 'UX' is not defined [221] */
/* p2c: datetime.inc, line 20:
 * Warning: Symbol 'MINUTE' is not defined [221] */
  second -= minute * 60;
  hour = minute / 60;
/* p2c: datetime.inc, line 22:
 * Warning: Symbol 'HOUR' is not defined [221] */
  minute -= hour * 60;
  day = hour / 24;
/* p2c: datetime.inc, line 24: Warning: Symbol 'DAY' is not defined [221] */
  hour -= day * 24;

/* p2c: datetime.inc, line 27:
 * Warning: Symbol 'YEAR' is not defined [221] */
/* p2c: datetime.inc, line 28: Warning: Symbol 'DOW' is not defined [221] */

  do {
    leap = ((year & 3) == 0 && (year % 100 != 0 || year % 400 == 0));
/* p2c: datetime.inc, line 31:
 * Warning: Symbol 'LEAP' is not defined [221] */
    daysInYear = 365;
/* p2c: datetime.inc, line 32:
 * Warning: Symbol 'DAYSINYEAR' is not defined [221] */
    if (leap)
      daysInYear++;
    if (day >= daysInYear) {
      dow++;
      if (leap)
	dow++;
      day -= daysInYear;
      if (dow >= 7)
	dow -= 7;
      year++;
    } else {
/* p2c: datetime.inc, line 41: Warning: Expected a '(', found a '.' [227] */
      dow += day;
      dow %= 7;
      month = 0;
/* p2c: datetime.inc, line 44:
 * Warning: Symbol 'MONTH' is not defined [221] */
      do {
	dim = daysInMonth[month];
/* p2c: datetime.inc, line 46:
 * Warning: Symbol 'DAYSINMONTH' is not defined [221] */
/* p2c: datetime.inc, line 46: Warning: Symbol 'DIM' is not defined [221] */
	if (month == 1 && leap)
	  dim++;
	if (day >= dim)
	  day -= dim;
	else
	  fin = true;
	month++;
      } while (!(fin || month == 12));
      fin = true;
    }
  } while (!fin);
/* p2c: datetime.inc, line 54: Warning: Expected a '(', found a '.' [227] */
/* p2c: datetime.inc, line 55: Warning: Expected a '(', found a '.' [227] */
/* p2c: datetime.inc, line 56: Warning: Expected a '(', found a '.' [227] */
/* p2c: datetime.inc, line 57: Warning: Expected a '(', found a '.' [227] */
/* p2c: datetime.inc, line 58: Warning: Expected a '(', found a '.' [227] */
/* p2c: datetime.inc, line 59: Warning: Expected a '(', found a '.' [227] */
/* p2c: datetime.inc, line 60: Warning: Expected a '(', found a '.' [227] */
  exit(EXIT_SUCCESS);
}
/* p2c: datetime.inc, line 63: 
 * Warning: Junk at end of input file ignored [277] */




/* End. */
