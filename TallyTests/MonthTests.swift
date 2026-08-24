import Foundation
import Testing

@testable import Tally

@Suite("Month keys and arithmetic")
struct MonthTests {
    @Test("Month keys are zero-padded yyyy-MM")
    func keyFormat() {
        let march = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 9))!
        #expect(Month.key(from: march) == "2026-03")
    }

    @Test("Shifting backwards crosses the year boundary")
    func shiftBackAcrossYear() {
        #expect(Month.shift("2026-01", by: -1) == "2025-12")
    }

    @Test("Shifting forwards crosses the year boundary")
    func shiftForwardAcrossYear() {
        #expect(Month.shift("2026-12", by: 1) == "2027-01")
    }

    @Test("Shifting by zero is the identity")
    func shiftIdentity() {
        #expect(Month.shift("2026-08", by: 0) == "2026-08")
    }

    @Test("Shifting by twelve lands on the same month a year out")
    func shiftFullYear() {
        #expect(Month.shift("2026-08", by: 12) == "2027-08")
    }

    @Test("ISO dates round-trip through parse and format")
    func isoRoundTrip() {
        #expect(Month.isoDate(Month.parseISO("2026-08-07")) == "2026-08-07")
    }

    @Test("A day in a non-current month defaults to the first")
    func defaultDateForOtherMonth() {
        #expect(Month.defaultDate(for: "1999-04") == "1999-04-01")
    }

    @Test("A day in the current month defaults to today")
    func defaultDateForCurrentMonth() {
        #expect(Month.defaultDate(for: Month.current) == Month.isoDate(Date()))
    }
}
