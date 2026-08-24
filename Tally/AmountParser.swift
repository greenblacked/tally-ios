import Foundation

/// Turns what someone typed into a decimal-pad field into an amount.
///
/// The system keyboard shows whichever decimal separator the device locale uses,
/// so the same tap produces "0.99" in the US and "0,99" in France. Both mean
/// ninety-nine cents. Treating only "." as decimal — and silently deleting the
/// comma — turns that into ninety-nine dollars, which is why this lives in its
/// own type with tests rather than inline in a view.
///
/// The rule: if both separators appear, the rightmost one is the decimal mark and
/// the other groups thousands. If only one appears, it is a grouping separator
/// when exactly three digits follow it and the locale does not use it as its
/// decimal mark — so "1,234" is a thousand and change, while "0,99" is not.
enum AmountParser {
    static func parse(_ raw: String, locale: Locale = .current) -> Double? {
        // Direction comes from the type picker, so a signed amount is ambiguous
        // rather than negative. Asking again beats guessing at "-5".
        guard !raw.contains("-"), !raw.contains("\u{2212}") else { return nil }

        let allowed = raw.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !allowed.isEmpty else { return nil }

        let lastDot = allowed.lastIndex(of: ".")
        let lastComma = allowed.lastIndex(of: ",")

        let decimalIndex: String.Index?
        switch (lastDot, lastComma) {
        case let (dot?, comma?):
            decimalIndex = dot > comma ? dot : comma
        case let (dot?, nil):
            decimalIndex = isGrouping(allowed, at: dot, locale: locale) ? nil : dot
        case let (nil, comma?):
            decimalIndex = isGrouping(allowed, at: comma, locale: locale) ? nil : comma
        case (nil, nil):
            decimalIndex = nil
        }

        var whole = ""
        var fraction = ""
        if let decimalIndex {
            whole = allowed[..<decimalIndex].filter(\.isNumber)
            fraction = allowed[allowed.index(after: decimalIndex)...].filter(\.isNumber)
        } else {
            whole = allowed.filter(\.isNumber)
        }
        guard !whole.isEmpty || !fraction.isEmpty else { return nil }
        guard let total = cents(whole: whole, fraction: fraction), total > 0 else { return nil }
        return Double(total) / 100
    }

    /// Rounds on the digits rather than through `Double`. Binary floating point
    /// stores 1.005 as slightly less than it, so `(1.005 * 100).rounded()` gives
    /// 100 and quietly loses the cent.
    private static func cents(whole: String, fraction: String) -> Int? {
        guard let units = Int(whole.isEmpty ? "0" : whole) else { return nil }
        var digits = Array(fraction.prefix(3))
        while digits.count < 3 { digits.append("0") }
        let tenths = digits[0].wholeNumberValue ?? 0
        let hundredths = digits[1].wholeNumberValue ?? 0
        let thousandths = digits[2].wholeNumberValue ?? 0
        let (scaled, overflow) = units.multipliedReportingOverflow(by: 100)
        guard !overflow else { return nil }
        return scaled + tenths * 10 + hundredths + (thousandths >= 5 ? 1 : 0)
    }

    private static func isGrouping(_ text: String, at index: String.Index, locale: Locale) -> Bool {
        if String(text[index]) == (locale.decimalSeparator ?? ".") { return false }
        return text[text.index(after: index)...].filter(\.isNumber).count == 3
    }
}
