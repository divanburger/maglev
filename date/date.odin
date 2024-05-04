package date

import tm "core:time"

SECONDS_PER_DAY :: 60 * 60 * 24
DAYS_PER_WEEK :: 7

Date :: distinct i64

Day :: Date(1)
Week :: DAYS_PER_WEEK * Day

date :: proc "contextless" (t: tm.Time) -> Date {
	return Date(t._nsec / (1e9 * SECONDS_PER_DAY))
}

time :: proc "contextless" (d: Date) -> tm.Time {
	return { i64(d) * 1e9 * SECONDS_PER_DAY }
}

now :: proc() -> Date {
	return date(tm.now())
}

day :: proc "contextless" (d: Date) -> int {
	return tm.day(time(d))
}

weekday :: proc(d: Date) -> tm.Weekday {
	return tm.weekday(time(d))
}

month :: proc "contextless" (d: Date) -> tm.Month {
	return tm.month(time(d))
}

date_add_days :: proc "contextless" (d: Date, days: int) -> Date {
	return Date(int(d) + days)
}