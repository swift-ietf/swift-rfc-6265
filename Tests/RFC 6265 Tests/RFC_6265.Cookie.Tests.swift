import Testing

@testable import RFC_6265

struct RFC_6265_Cookie_Tests {}

extension RFC_6265_Cookie_Tests {
    @Suite
    struct Unit {
        @Test
        func `parses a single cookie pair`() throws {
            let cookie = try RFC_6265.Cookie("SID=31d4d96e407aad42")
            #expect(cookie.pairs == [.init(name: "SID", value: "31d4d96e407aad42")])
        }

        @Test
        func `parses multiple cookie pairs in order`() throws {
            let cookie = try RFC_6265.Cookie("SID=31d4d96e407aad42; lang=en-US")
            #expect(
                cookie.pairs == [
                    .init(name: "SID", value: "31d4d96e407aad42"),
                    .init(name: "lang", value: "en-US"),
                ]
            )
        }

        @Test
        func `serializes pairs joined by the pair delimiter`() {
            let cookie = RFC_6265.Cookie(
                pairs: [
                    .init(name: "SID", value: "31d4d96e407aad42"),
                    .init(name: "lang", value: "en-US"),
                ]
            )
            #expect(cookie.headerValue == "SID=31d4d96e407aad42; lang=en-US")
            #expect(cookie.description == cookie.headerValue)
        }

        @Test
        func `pair splits on the first equals sign only`() throws {
            let pair = try RFC_6265.Cookie.Pair("token=a=b=c")
            #expect(pair.name == "token")
            #expect(pair.value == "a=b=c")
        }

        @Test
        func `pair without separator throws`() {
            #expect(throws: RFC_6265.Cookie.Pair.Error.missingNameValueSeparator("junk")) {
                try RFC_6265.Cookie.Pair.parse("junk")
            }
        }
    }

    @Suite
    struct `Edge Case` {
        @Test
        func `empty cookie string throws`() {
            #expect(throws: RFC_6265.Cookie.Error.emptyCookieString) {
                try RFC_6265.Cookie.parse("")
            }
        }

        @Test
        func `segment without separator rejects the cookie string`() {
            #expect(
                throws: RFC_6265.Cookie.Error.invalidPair(
                    "junk",
                    .missingNameValueSeparator("junk")
                )
            ) {
                try RFC_6265.Cookie.parse("a=1; junk; b=2")
            }
        }

        @Test
        func `lenient parse skips segments without separator`() {
            let cookie = RFC_6265.Cookie.parse(skippingInvalidPairs: "a=1; junk; b=2")
            #expect(
                cookie.pairs == [
                    .init(name: "a", value: "1"),
                    .init(name: "b", value: "2"),
                ]
            )
        }

        @Test
        func `empty value is preserved`() throws {
            let cookie = try RFC_6265.Cookie("a=")
            #expect(cookie.pairs == [.init(name: "a", value: "")])
            #expect(cookie.headerValue == "a=")
        }

        @Test
        func `empty name is preserved`() throws {
            let cookie = try RFC_6265.Cookie("=v")
            #expect(cookie.pairs == [.init(name: "", value: "v")])
        }

        @Test
        func `semicolon without following space is not a pair delimiter`() throws {
            let cookie = try RFC_6265.Cookie("a=1;b=2")
            #expect(cookie.pairs == [.init(name: "a", value: "1;b=2")])
        }

        @Test
        func `quoted value is stored verbatim`() throws {
            let cookie = try RFC_6265.Cookie(#"a="quoted""#)
            #expect(cookie.pairs == [.init(name: "a", value: #""quoted""#)])
            #expect(cookie.headerValue == #"a="quoted""#)
        }
    }

    @Suite
    struct Integration {
        @Test
        func `cookie string round-trips through parse and serialize`() throws {
            let value = "SID=31d4d96e407aad42; lang=en-US; theme=; a=b=c"
            let cookie = try RFC_6265.Cookie(value)
            #expect(cookie.headerValue == value)
            #expect(try RFC_6265.Cookie(cookie.headerValue) == cookie)
        }

        @Test
        func `lenient parse matches strict parse on well-formed input`() throws {
            let value = "SID=31d4d96e407aad42; lang=en-US"
            #expect(RFC_6265.Cookie.parse(skippingInvalidPairs: value) == (try RFC_6265.Cookie.parse(value)))
        }
    }
}
