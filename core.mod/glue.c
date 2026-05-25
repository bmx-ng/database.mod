/*
  Copyright (c) 2007-2026 Bruce A Henderson
  All rights reserved.
 
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
      * Neither the auther nor the names of its contributors may be used to 
        endorse or promote products derived from this software without specific
        prior written permission.
 
  THIS SOFTWARE IS PROVIDED BY Bruce A Henderson ``AS IS'' AND ANY
  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL Bruce A Henderson BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <time.h>
#include "blitz.h"

BBString * _formatDate(BBString * format, int y, int m, int d, int hh, int mm, int ss, int micros) {

	char fmtbuf[1024];
	char buffer[1024];
	struct tm stm = {0};
	char * p = bbStringToUTF8String(format);

	char us[7];
	snprintf(us, sizeof(us), "%06d", micros);

	/* replace %f with microseconds */
	char * src = p;
	char * dst = fmtbuf;
	char * end = fmtbuf + sizeof(fmtbuf) - 1;
	while (*src && dst < end) {
		if (src[0] == '%' && src[1] == 'f') {
			for (int i = 0; i < 6 && dst < end; ++i) {
				*dst++ = us[i];
			}
			src += 2;
		} else {
			*dst++ = *src++;
		}
	}
	*dst = 0;
	stm.tm_year = y - 1900;
	stm.tm_mon = m - 1;
	stm.tm_mday = d;
	stm.tm_hour = hh;
	stm.tm_min = mm;
	stm.tm_sec = ss;
	stm.tm_isdst = -1;
	if (!strftime(buffer, sizeof(buffer), fmtbuf, &stm)) {
		buffer[0] = 0;
	}
	bbMemFree(p);
	return bbStringFromUTF8String(buffer);
}

static int db_is_leap_year(int y) {
	return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
}

static BBInt64 db_days_from_civil(int y, unsigned m, unsigned d) {
	y -= m <= 2;
	const int era = (y >= 0 ? y : y - 399) / 400;
	const unsigned yoe = (unsigned)(y - era * 400);
	const unsigned doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
	const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
	return (BBInt64)era * 146097 + (BBInt64)doe - 719468;
}

static void db_civil_from_days(BBInt64 z, int * y, unsigned * m, unsigned * d) {
	z += 719468;
	const BBInt64 era = (z >= 0 ? z : z - 146096) / 146097;
	const unsigned doe = (unsigned)(z - era * 146097);
	const unsigned yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
	const BBInt64 yy = (BBInt64)yoe + era * 400;
	const unsigned doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
	const unsigned mp = (5 * doy + 2) / 153;
	*d = doy - (153 * mp + 2) / 5 + 1;
	*m = mp + (mp < 10 ? 3 : -9);
	*y = (int)(yy + (*m <= 2));
}

void _calcDateValue(BBInt64 * value, int y, int m, int d, int hh, int mm, int ss) {
	BBInt64 days = db_days_from_civil(y, (unsigned)m, (unsigned)d);
	*value = days * 86400LL
		+ (BBInt64)hh * 3600LL
		+ (BBInt64)mm * 60LL
		+ (BBInt64)ss;
}

int _splitDateValue(BBInt64 value, int * y, int * m, int * d, int * hh, int * mm, int * ss) {
	BBInt64 days = value / 86400LL;
	BBInt64 rem = value % 86400LL;
	if (rem < 0) {
		rem += 86400LL;
		days -= 1;
	}
	unsigned um;
	unsigned ud;
	db_civil_from_days(days, y, &um, &ud);
	*m = (int)um;
	*d = (int)ud;
	*hh = (int)(rem / 3600LL);
	rem %= 3600LL;
	*mm = (int)(rem / 60LL);
	*ss = (int)(rem % 60LL);
	return 1;
}
