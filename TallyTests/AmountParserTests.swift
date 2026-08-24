import Foundation
import Testing

@testable import Tally

private let us = Locale(identifier: "en_US")
private let fr = Locale(identifier: "fr_FR")
private let de = Locale(identifier: "de_DE")

@Suite("Amount parsing")
struct AmountParserTests {
    @Test("Plain decimals parse in a full-stop locale")
    func plainDecimals() {
        #expect(AmountParser.parse("0.99", locale: us) == 0.99)
        #expect(AmountParser.parse("310.20", locale: us) == 310.20)
        #expect(AmountParser.parse("5", locale: us) == 5)
    }

    @Test("A comma decimal separator is cents, not a hundredfold error")
    func commaIsDecimal() {
        // The bug this type exists to prevent: 0,99 must never become 99.
        #expect(AmountParser.parse("0,99", locale: fr) == 0.99)
        #expect(AmountParser.parse("310,20", locale: fr) == 310.20)
        #expect(AmountParser.parse("12,00", locale: de) == 12)
    }

    @Test("A comma decimal is still read correctly in a full-stop locale")
    func commaDecimalInUSLocale() {
        // Someone typing on a European hardware keyboard into a US-locale device.
        #expect(AmountParser.parse("0,99", locale: us) == 0.99)
    }

    @Test("Three trailing digits after a lone separator means thousands")
    func groupingSeparator() {
        #expect(AmountParser.parse("1,234", locale: us) == 1234)
        #expect(AmountParser.parse("1.234", locale: fr) == 1234)
    }

    @Test("Both separators present: the rightmost is the decimal mark")
    func mixedSeparators() {
        #expect(AmountParser.parse("1,234.50", locale: us) == 1234.50)
        #expect(AmountParser.parse("1.234,50", locale: fr) == 1234.50)
        #expect(AmountParser.parse("1 234,50", locale: fr) == 1234.50)
    }

    @Test("Currency symbols and stray text are ignored")
    func stripsNonDigits() {
        #expect(AmountParser.parse("$42.50", locale: us) == 42.50)
        #expect(AmountParser.parse("42,50 €", locale: fr) == 42.50)
    }

    @Test("Amounts round to cents")
    func rounding() {
        #expect(AmountParser.parse("1.005", locale: us) == 1.01)
        #expect(AmountParser.parse("1.004", locale: us) == 1.00)
    }

    @Test("Zero, blank, and junk are rejected")
    func rejectsNonAmounts() {
        #expect(AmountParser.parse("", locale: us) == nil)
        #expect(AmountParser.parse("0", locale: us) == nil)
        #expect(AmountParser.parse("0.00", locale: us) == nil)
        #expect(AmountParser.parse("abc", locale: us) == nil)
        #expect(AmountParser.parse(".", locale: us) == nil)
        #expect(AmountParser.parse("-5", locale: us) == nil)
    }

    @Test("What Money.editable writes, AmountParser reads back")
    func roundTripsWithEditable() {
        for amount in [1850.0, 310.20, 5.75, 88.10, 2800.0] {
            #expect(AmountParser.parse(Money.editable(amount)) == amount)
        }
    }
}
