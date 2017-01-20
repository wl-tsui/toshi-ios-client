import Foundation

struct DateTimeFormatter {
    static var oneDayTimeInterval: TimeInterval = 60 * 60 * 24

    static var oneWeekTimeInterval: TimeInterval = 60 * 60 * 24 * 7

    static var dateFormatter: DateFormatter {
        let dt = DateFormatter()
        dt.locale = Locale.current
        dt.timeStyle = .none
        dt.dateStyle = .short

        return dt
    }

    static var weekdayFormatter: DateFormatter {
        let dt = DateFormatter()
        dt.locale = Locale.current
        dt.dateFormat = "EEEE"

        return dt
    }

    static var timeFormatter: DateFormatter {
        let dt = DateFormatter()
        dt.locale = Locale.current
        dt.timeStyle = .short
        dt.dateStyle = .none

        return dt
    }

    static func dateOlderThanOneDay(date: Date) -> Bool {
        return Date().timeIntervalSince(date) > self.oneDayTimeInterval
    }

    static func dateOlderThanOneWeek(date: Date) -> Bool {
        return Date().timeIntervalSince(date) > self.oneWeekTimeInterval
    }

    static func isDate(_ date: Date, sameDayAs anotherDate: Date) -> Bool {
        let componentFlags: Set<Calendar.Component> = [.year, .month, .day]
        let components1 = Calendar.autoupdatingCurrent.dateComponents(componentFlags, from: date)
        let components2 = Calendar.autoupdatingCurrent.dateComponents(componentFlags, from: anotherDate)

        return (components1.year == components2.year) && (components1.month == components2.month) && (components1.day == components2.day)
    }
}
