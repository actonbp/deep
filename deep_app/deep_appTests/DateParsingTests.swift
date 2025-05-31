import Foundation
import Testing
@testable import deep_app

struct DateParsingTests {

    @Test func parses12HourTime() async throws {
        let vm = ChatViewModel()
        guard let date = vm.dateForToday(from: "9:00 AM") else {
            throw TestFailure("Expected non-nil date for valid 12-hour time string")
        }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(comps.hour == 9)
        #expect(comps.minute == 0)
    }

    @Test func parses24HourTime() async throws {
        let vm = ChatViewModel()
        guard let date = vm.dateForToday(from: "14:30") else {
            throw TestFailure("Expected non-nil date for valid 24-hour time string")
        }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        #expect(comps.hour == 14)
        #expect(comps.minute == 30)
    }

    @Test func returnsNilForInvalidTime() async throws {
        let vm = ChatViewModel()
        let invalid = vm.dateForToday(from: "not a time")
        #expect(invalid == nil)
    }
}