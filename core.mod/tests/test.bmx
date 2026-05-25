SuperStrict

Framework brl.standardio
Import BRL.MaxUnit
Import Database.Core

New TTestSuite.run()

Type TDBStrptimeTest Extends TTest

	Method AssertParsed(date:String, fmt:String, ey:Int, em:Int, ed:Int, eh:Int, emin:Int, es:Int, msg:String)
		Local y:Int, m:Int, d:Int, hh:Int, mm:Int, ss:Int, micros:Int

		AssertTrue(dbStrptime(date, fmt, y, m, d, hh, mm, ss, micros), msg + " should parse")
		AssertEquals(ey, y, msg + " year")
		AssertEquals(em, m, msg + " month")
		AssertEquals(ed, d, msg + " day")
		AssertEquals(eh, hh, msg + " hour")
		AssertEquals(emin, mm, msg + " minute")
		AssertEquals(es, ss, msg + " second")
		AssertEquals(0, micros, msg + " microsecond")
	End Method

	Method AssertNotParsed(date:String, fmt:String, msg:String)
		Local y:Int, m:Int, d:Int, hh:Int, mm:Int, ss:Int, micros:Int
		AssertFalse(dbStrptime(date, fmt, y, m, d, hh, mm, ss, micros), msg + " should not parse")
	End Method

	Method TestParseDate() { test }
		AssertParsed("2024-02-29", "%Y-%m-%d", 2024, 2, 29, 0, 0, 0, "date")
	End Method

	Method TestParseDateTime() { test }
		AssertParsed("2024-12-31 23:59:58", "%Y-%m-%d %H:%M:%S", 2024, 12, 31, 23, 59, 58, "datetime")
	End Method

	Method TestParseTime() { test }
		AssertParsed("09:08:07", "%H:%M:%S", 0, 0, 0, 9, 8, 7, "time")
	End Method

	Method TestSingleDigitParts() { test }
		AssertParsed("2024-1-2 3:4:5", "%Y-%m-%d %H:%M:%S", 2024, 1, 2, 3, 4, 5, "single digit parts")
	End Method

	Method TestWhitespace() { test }
		AssertParsed("2024-01-02     03:04:05", "%Y-%m-%d %H:%M:%S", 2024, 1, 2, 3, 4, 5, "extra whitespace")
	End Method

	Method TestLiteralPercent() { test }
		AssertParsed("2024%01%02", "%Y%%%m%%%d", 2024, 1, 2, 0, 0, 0, "literal percent")
	End Method

	Method TestBadSeparatorsFail() { test }
		AssertNotParsed("2024/01/02", "%Y-%m-%d", "wrong date separator")
		AssertNotParsed("12-34-56", "%H:%M:%S", "wrong time separator")
	End Method

	Method TestInvalidRangesFail() { test }
		AssertNotParsed("2024-00-01", "%Y-%m-%d", "month zero")
		AssertNotParsed("2024-13-01", "%Y-%m-%d", "month thirteen")
		AssertNotParsed("2024-01-32", "%Y-%m-%d", "day thirty two")
		AssertNotParsed("24:00:00", "%H:%M:%S", "hour twenty four")
		AssertNotParsed("23:60:00", "%H:%M:%S", "minute sixty")
		AssertNotParsed("23:59:60", "%H:%M:%S", "second sixty")
	End Method

	Method TestNonDigitsFail() { test }
		AssertNotParsed("abcd-01-01", "%Y-%m-%d", "non digit year")
		AssertNotParsed("2024-aa-01", "%Y-%m-%d", "non digit month")
		AssertNotParsed("2024-01-aa", "%Y-%m-%d", "non digit day")
		AssertNotParsed("aa:00:00", "%H:%M:%S", "non digit hour")
		AssertNotParsed("00:aa:00", "%H:%M:%S", "non digit minute")
		AssertNotParsed("00:00:aa", "%H:%M:%S", "non digit second")
	End Method

	Method TestIncompleteInputFails() { test }
		AssertNotParsed("", "%Y-%m-%d", "empty input")
		AssertNotParsed("2024", "%Y-%m-%d", "partial date")
		AssertNotParsed("2024-01", "%Y-%m-%d", "partial date month")
		AssertNotParsed("12:34", "%H:%M:%S", "partial time")
	End Method

	Method TestTrailingGarbageFails() { test }
		AssertNotParsed("2024-01-02abc", "%Y-%m-%d", "trailing text")
		AssertNotParsed("12:34:56zzz", "%H:%M:%S", "trailing text time")
	End Method

	Method TestTrailingWhitespaceAllowed() { test }
		AssertParsed("2024-01-02   ", "%Y-%m-%d", 2024, 1, 2, 0, 0, 0, "trailing whitespace")
	End Method

End Type

Type TDBStrptimeFractionTest Extends TTest

	Method AssertParsed(date:String, fmt:String, ey:Int, em:Int, ed:Int, eh:Int, emin:Int, es:Int, msg:String)
		Local y:Int, m:Int, d:Int, hh:Int, mm:Int, ss:Int, micros:Int

		AssertTrue(dbStrptime(date, fmt, y, m, d, hh, mm, ss, micros), msg + " should parse")
		AssertEquals(ey, y, msg + " year")
		AssertEquals(em, m, msg + " month")
		AssertEquals(ed, d, msg + " day")
		AssertEquals(eh, hh, msg + " hour")
		AssertEquals(emin, mm, msg + " minute")
		AssertEquals(es, ss, msg + " second")
		AssertEquals(0, micros, msg + " microsecond")
	End Method

	Method AssertNotParsed(date:String, fmt:String, msg:String)
		Local y:Int, m:Int, d:Int, hh:Int, mm:Int, ss:Int, micros:Int
		AssertFalse(dbStrptime(date, fmt, y, m, d, hh, mm, ss, micros), msg + " should not parse")
	End Method

	Method AssertParsedMicros(date:String, fmt:String, expectedMicros:Int, msg:String)
		Local y:Int, m:Int, d:Int, hh:Int, mm:Int, ss:Int, micros:Int

		AssertTrue(dbStrptime(date, fmt, y, m, d, hh, mm, ss, micros), msg + " should parse")
		AssertEquals(expectedMicros, micros, msg + " micros")
	End Method

	Method AssertNotParsedMicros(date:String, fmt:String, msg:String)
		Local y:Int, m:Int, d:Int, hh:Int, mm:Int, ss:Int, micros:Int
		AssertFalse(dbStrptime(date, fmt, y, m, d, hh, mm, ss, micros), msg + " should not parse")
	End Method

	Method TestFractionalSeconds() { test }
		AssertParsedMicros("12:34:56.1", "%H:%M:%S.%f", 100000, "one digit fraction")
		AssertParsedMicros("12:34:56.12", "%H:%M:%S.%f", 120000, "two digit fraction")
		AssertParsedMicros("12:34:56.123", "%H:%M:%S.%f", 123000, "three digit fraction")
		AssertParsedMicros("12:34:56.123456", "%H:%M:%S.%f", 123456, "six digit fraction")
	End Method

	Method TestFractionalSecondsRequiresDigits() { test }
		AssertNotParsedMicros("12:34:56.", "%H:%M:%S.%f", "missing fraction")
		AssertNotParsedMicros("12:34:56.abcdef", "%H:%M:%S.%f", "non digit fraction")
	End Method

	Method TestFractionalSecondsRejectsTooManyDigits() { test }
		AssertNotParsedMicros("12:34:56.1234567", "%H:%M:%S.%f", "seven digit fraction")
	End Method

	Method TestDateTimeWithFraction() { test }
		Local y:Int, m:Int, d:Int, hh:Int, mm:Int, ss:Int, micros:Int

		AssertTrue(dbStrptime("2024-01-02 03:04:05.987654", "%Y-%m-%d %H:%M:%S.%f", y, m, d, hh, mm, ss, micros), "datetime with fraction should parse")

		AssertEquals(2024, y, "year")
		AssertEquals(1, m, "month")
		AssertEquals(2, d, "day")
		AssertEquals(3, hh, "hour")
		AssertEquals(4, mm, "minute")
		AssertEquals(5, ss, "second")
		AssertEquals(987654, micros, "micros")
	End Method

	Method TestUnknownFormatSpecifierFails() { test }
		AssertNotParsed("2024-01-02", "%Y-%q-%d", "unknown specifier")
	End Method

	Method TestFormatEndsWithPercentFails() { test }
		AssertNotParsed("2024-", "%Y-%", "format ending with percent")
	End Method

	Method TestEmptyFormat() { test }
		AssertParsed("", "", 0, 0, 0, 0, 0, 0, "empty format and empty input")
		AssertNotParsed("abc", "", "empty format with non-empty input")
	End Method

	Method TestZeroFraction() { test }
		AssertParsedMicros("12:34:56.0", "%H:%M:%S.%f", 0, "zero fraction")
		AssertParsedMicros("12:34:56.000000", "%H:%M:%S.%f", 0, "zero six digit fraction")
	End Method

	Method TestMaxValidValues() { test }
		AssertParsed("9999-12-31 23:59:59", "%Y-%m-%d %H:%M:%S", 9999, 12, 31, 23, 59, 59, "max common datetime")
	End Method
End Type

Type TDBDateValidationTest Extends TTest

	Method AssertValidDate(y:Int, m:Int, d:Int, msg:String)
		AssertTrue(dbIsValidDate(y, m, d), msg + " should be valid")
	End Method

	Method AssertInvalidDate(y:Int, m:Int, d:Int, msg:String)
		AssertFalse(dbIsValidDate(y, m, d), msg + " should be invalid")
	End Method

	Method TestValidDates() { test }
		AssertValidDate(2024, 1, 1, "new year")
		AssertValidDate(2024, 12, 31, "end of year")
		AssertValidDate(2024, 2, 29, "leap day")
		AssertValidDate(2000, 2, 29, "century leap year")
	End Method

	Method TestInvalidMonths() { test }
		AssertInvalidDate(2024, 0, 1, "month zero")
		AssertInvalidDate(2024, 13, 1, "month thirteen")
	End Method

	Method TestInvalidDays() { test }
		AssertInvalidDate(2024, 1, 0, "day zero")
		AssertInvalidDate(2024, 1, 32, "january thirty two")
		AssertInvalidDate(2024, 4, 31, "april thirty one")
		AssertInvalidDate(2024, 6, 31, "june thirty one")
		AssertInvalidDate(2024, 9, 31, "september thirty one")
		AssertInvalidDate(2024, 11, 31, "november thirty one")
	End Method

	Method TestFebruaryLeapYears() { test }
		AssertValidDate(2024, 2, 29, "normal leap year")
		AssertInvalidDate(2023, 2, 29, "non leap year")
		AssertInvalidDate(1900, 2, 29, "century non leap year")
		AssertValidDate(2000, 2, 29, "century leap year")
		AssertInvalidDate(2024, 2, 30, "february thirty")
	End Method

	Method TestYearBounds() { test }
		AssertInvalidDate(0, 1, 1, "year zero")
		AssertInvalidDate(-1, 1, 1, "negative year")
		AssertValidDate(1, 1, 1, "minimum positive year")
	End Method

End Type


Type TDBDateTest Extends TTest

	Method AssertDateParts(d:TDBDate, y:Int, m:Int, day:Int, msg:String)
		AssertNotNull(d, msg + " should not be null object")
		AssertFalse(d.isNull(), msg + " should not be DB null")
		AssertEquals(y, d.getYear(), msg + " year")
		AssertEquals(m, d.getMonth(), msg + " month")
		AssertEquals(day, d.getDay(), msg + " day")
	End Method

	Method TestSetFromParts() { test }
		Local d:TDBDate = TDBDate.Set(2024, 2, 29)

		AssertDateParts(d, 2024, 2, 29, "date from parts")
		AssertEquals("2024-02-29", d.getString(), "default string")
		AssertEquals("2024/02/29", d.format("%Y/%m/%d"), "custom format")
	End Method

	Method TestSetFromString() { test }
		Local d:TDBDate = TDBDate.SetFromString("2024-12-31")

		AssertDateParts(d, 2024, 12, 31, "date from string")
		AssertEquals("2024-12-31", d.format(), "formatted string")
	End Method

	Method TestSetWithLong() { test }
		Local original:TDBDate = TDBDate.Set(2024, 1, 2)
		Local d:TDBDate = TDBDate.SetWithLong(original.getDate())

		AssertDateParts(d, 2024, 1, 2, "date from long")
		AssertEquals("2024-01-02", d.format(), "formatted long date")
	End Method

	Method TestClear() { test }
		Local d:TDBDate = TDBDate.Set(2024, 1, 2)

		d.clear()

		AssertTrue(d.isNull(), "cleared date should be null")
		AssertEquals(0:Long, d.getDate(), "cleared value")
	End Method

	Method TestKind() { test }
		Local d:TDBDate = TDBDate.Set(2024, 1, 2)
		AssertEquals(DBTYPE_DATE, d.kind(), "date kind")
	End Method

	Method TestInvalidDateFromPartsBecomesNull() { test }
		Local d:TDBDate = TDBDate.Set(2024, 2, 30)

		AssertNotNull(d, "invalid date still returns object")
		AssertTrue(d.isNull(), "invalid date should be DB null")
	End Method

	Method TestInvalidDateFromStringReturnsNull() { test }
		AssertNull(TDBDate.SetFromString("2024-02-30"), "invalid calendar date")
		AssertNull(TDBDate.SetFromString("2024-13-01"), "invalid month")
		AssertNull(TDBDate.SetFromString("not-a-date"), "invalid syntax")
	End Method

	Method TestTrailingGarbageRejected() { test }
		AssertNull(TDBDate.SetFromString("2024-01-02abc"), "trailing garbage should reject")
	End Method

End Type

Type TDBDateTimeTest Extends TTest

	Method AssertDateTimeParts(dt:TDBDateTime, y:Int, m:Int, d:Int, hh:Int, mm:Int, ss:Int, msg:String)
		AssertNotNull(dt, msg + " should not be null object")
		AssertFalse(dt.isNull(), msg + " should not be DB null")
		AssertEquals(y, dt.getYear(), msg + " year")
		AssertEquals(m, dt.getMonth(), msg + " month")
		AssertEquals(d, dt.getDay(), msg + " day")
		AssertEquals(hh, dt.getHour(), msg + " hour")
		AssertEquals(mm, dt.getMinute(), msg + " minute")
		AssertEquals(ss, dt.getSecond(), msg + " second")
	End Method

	Method TestSetFromParts() { test }
		Local dt:TDBDateTime = TDBDateTime.Set(2024, 2, 29, 23, 59, 58)

		AssertDateTimeParts(dt, 2024, 2, 29, 23, 59, 58, "datetime from parts")
		AssertEquals("2024-02-29 23:59:58", dt.getString(), "default string")
		AssertEquals("2024/02/29 23:59:58", dt.format("%Y/%m/%d %H:%M:%S"), "custom format")
	End Method

	Method TestSetFromString() { test }
		Local dt:TDBDateTime = TDBDateTime.SetFromString("2024-12-31 03:04:05")
		AssertDateTimeParts(dt, 2024, 12, 31, 3, 4, 5, "datetime from string")
	End Method

	Method TestSetWithLong() { test }
		Local original:TDBDateTime = TDBDateTime.Set(2024, 1, 2, 3, 4, 5)
		Local dt:TDBDateTime = TDBDateTime.SetWithLong(original.getDate())

		AssertDateTimeParts(dt, 2024, 1, 2, 3, 4, 5, "datetime from long")
	End Method

	Method TestClear() { test }
		Local dt:TDBDateTime = TDBDateTime.Set(2024, 1, 2, 3, 4, 5)

		dt.clear()

		AssertTrue(dt.isNull(), "cleared datetime should be null")
		AssertEquals(0:Long, dt.getDate(), "cleared value")
	End Method

	Method TestKind() { test }
		Local dt:TDBDateTime = TDBDateTime.Set(2024, 1, 2, 3, 4, 5)
		AssertEquals(DBTYPE_DATETIME, dt.kind(), "datetime kind")
	End Method

	Method TestInvalidDateFromPartsBecomesNull() { test }
		Local dt:TDBDateTime = TDBDateTime.Set(2024, 2, 30, 12, 0, 0)

		AssertNotNull(dt, "invalid datetime still returns object")
		AssertTrue(dt.isNull(), "invalid date should be DB null")
	End Method

	Method TestInvalidTimeFromPartsBecomesNull() { test }
		Local dt:TDBDateTime = TDBDateTime.Set(2024, 1, 2, 24, 0, 0)

		AssertNotNull(dt, "invalid datetime still returns object")
		AssertTrue(dt.isNull(), "invalid time should be DB null")
	End Method

	Method TestInvalidDateTimeFromStringReturnsNull() { test }
		AssertNull(TDBDateTime.SetFromString("2024-02-30 12:00:00"), "invalid date")
		AssertNull(TDBDateTime.SetFromString("2024-01-02 24:00:00"), "invalid hour")
		AssertNull(TDBDateTime.SetFromString("not-a-datetime"), "invalid syntax")
	End Method

	Method TestTrailingGarbageRejected() { test }
		AssertNull(TDBDateTime.SetFromString("2024-01-02 03:04:05abc"), "trailing garbage should reject")
	End Method

End Type

Type TDBTimeTest Extends TTest

	Method AssertTimeParts(t:TDBTime, hh:Int, mm:Int, ss:Int, msg:String)
		AssertNotNull(t, msg + " should not be null object")
		AssertFalse(t.isNull(), msg + " should not be DB null")
		AssertEquals(hh, t.getHour(), msg + " hour")
		AssertEquals(mm, t.getMinute(), msg + " minute")
		AssertEquals(ss, t.getSecond(), msg + " second")
	End Method

	Method TestSetFromParts() { test }
		Local t:TDBTime = TDBTime.Set(23, 59, 58)

		AssertTimeParts(t, 23, 59, 58, "time from parts")
		AssertEquals("23:59:58", t.getString(), "default string")
		AssertEquals("23-59-58", t.format("%H-%M-%S"), "custom format")
	End Method

	Method TestSetFromString() { test }
		Local t:TDBTime = TDBTime.SetFromString("03:04:05")
		AssertTimeParts(t, 3, 4, 5, "time from string")
	End Method

	Method TestSetWithLong() { test }
		Local original:TDBTime = TDBTime.Set(3, 4, 5)
		Local t:TDBTime = TDBTime.SetWithLong(original.getDate())

		AssertTimeParts(t, 3, 4, 5, "time from long")
	End Method

	Method TestClear() { test }
		Local t:TDBTime = TDBTime.Set(3, 4, 5)

		t.clear()

		AssertTrue(t.isNull(), "cleared time should be null")
		AssertEquals(0:Long, t.getDate(), "cleared value")
	End Method

	Method TestKind() { test }
		Local t:TDBTime = TDBTime.Set(3, 4, 5)
		AssertEquals(DBTYPE_TIME, t.kind(), "time kind")
	End Method

	Method TestInvalidTimeFromPartsBecomesNull() { test }
		AssertTrue(TDBTime.Set(24, 0, 0).isNull(), "hour 24 should be null")
		AssertTrue(TDBTime.Set(23, 60, 0).isNull(), "minute 60 should be null")
		AssertTrue(TDBTime.Set(23, 59, 60).isNull(), "second 60 should be null")
		AssertTrue(TDBTime.Set(-1, 0, 0).isNull(), "negative hour should be null")
	End Method

	Method TestInvalidTimeFromStringReturnsNull() { test }
		AssertNull(TDBTime.SetFromString("24:00:00"), "invalid hour")
		AssertNull(TDBTime.SetFromString("23:60:00"), "invalid minute")
		AssertNull(TDBTime.SetFromString("23:59:60"), "invalid second")
		AssertNull(TDBTime.SetFromString("not-a-time"), "invalid syntax")
	End Method

	Method TestTrailingGarbageRejected() { test }
		AssertNull(TDBTime.SetFromString("03:04:05abc"), "trailing garbage should reject")
	End Method

	Method TestFractionalSeconds() { test }
		Local t:TDBTime = TDBTime.Set(3, 4, 5, 123456)

		AssertTimeParts(t, 3, 4, 5, "fractional time")
		AssertEquals(123456, t.getMicrosecond(), "microsecond")
		AssertEquals(123, t.getMillisecond(), "millisecond")
		AssertEquals("03:04:05.123456", t.format("%H:%M:%S.%f"), "fractional format")
	End Method

	Method TestFractionalSecondsFromString() { test }
		Local t:TDBTime = TDBTime.SetFromString("03:04:05.123456")

		AssertTimeParts(t, 3, 4, 5, "fractional time from string")
		AssertEquals(123456, t.getMicrosecond(), "microsecond")
	End Method

	Method TestInvalidFractionalSeconds() { test }
		AssertTrue(TDBTime.Set(3, 4, 5, -1).isNull(), "negative micros should be null")
		AssertTrue(TDBTime.Set(3, 4, 5, 1000000).isNull(), "micros too large should be null")
		AssertNull(TDBTime.SetFromString("03:04:05.1234567"), "too many fractional digits")
	End Method

End Type
