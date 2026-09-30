import Testing

@testable import RFC_6265

@Suite
struct `Set-Cookie Max-Age grammar` {
    @Test(arguments: ["+5", " +5", "5 5", "0x10"])
    func `a Max-Age that is not an optional minus and digits is invalid`(_ value: String) {
        #expect(throws: RFC_6265.SetCookie.Error.self) {
            try RFC_6265.SetCookie("id=1; Max-Age=\(value)")
        }
    }

    @Test
    func `a Max-Age too large for Int is read as the largest value`() throws {
        let setCookie = try RFC_6265.SetCookie("id=1; Max-Age=99999999999999999999")
        #expect(setCookie.maxAge == Int.max)
    }

    @Test
    func `a negative Max-Age is kept and one too small for Int is read as the smallest value`() throws {
        #expect(try RFC_6265.SetCookie("id=1; Max-Age=-1").maxAge == -1)
        #expect(try RFC_6265.SetCookie("id=1; Max-Age=-99999999999999999999").maxAge == Int.min)
    }
}
