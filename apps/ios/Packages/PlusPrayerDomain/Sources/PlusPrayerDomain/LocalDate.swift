import Foundation

/// A calendar day with no time or zone (`Prayer.localDate`,
/// `User.lastListLocalDate`). Streaks and "held today" compare these, never
/// instants (streaks-reminders.md). Encodes as `YYYY-MM-DD`.
public struct LocalDate: Sendable, Hashable, Comparable, Codable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `calendar`'s time zone (the device's, by default).
    public init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    /// Parses `YYYY-MM-DD`.
    public init?(string: String) {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Midnight UTC of this day; only for day arithmetic.
    private var utcMidnight: Date {
        Self.utc.date(from: DateComponents(year: year, month: month, day: day))!
    }

    public func adding(days: Int) -> LocalDate {
        LocalDate(Self.utc.date(byAdding: .day, value: days, to: utcMidnight)!, calendar: Self.utc)
    }

    /// Whole days from `other` to this (positive when this is later).
    public func days(since other: LocalDate) -> Int {
        Self.utc.dateComponents([.day], from: other.utcMidnight, to: utcMidnight).day!
    }

    /// 0 = Sunday … 6 = Saturday: the `sealVariant` weekday convention.
    public var weekdayFromSunday: Int { Self.utc.component(.weekday, from: utcMidnight) - 1 }

    /// The start of this day in `calendar`'s time zone (for display).
    public func start(in calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    public static func < (a: LocalDate, b: LocalDate) -> Bool {
        (a.year, a.month, a.day) < (b.year, b.month, b.day)
    }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public init(from decoder: any Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        guard let date = LocalDate(string: string) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "Not YYYY-MM-DD: \(string)"))
        }
        self = date
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
