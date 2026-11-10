import Foundation
import RFC_9110
import Testing

@testable import RFC_6265

struct RFC_6265_Cookie_Tests {}

extension RFC_6265_Cookie_Tests {
    @Suite
    struct Unit {
        @Test
        func `the field names RFC 6265 registers are spelled as registered`() {
            #expect([RFC_9110.Field.Name.cookie, .setCookie].map(\.rawValue) == ["Cookie", "Set-Cookie"])
        }

        @Test
        func `parses a single cookie pair`() throws {
            let cookie = try RFC_6265.Cookie("SID=31d4d96e407aad42")
            #expect(try cookie.pairs == [.init(name: "SID", value: "31d4d96e407aad42")])
        }

        @Test
        func `parses multiple cookie pairs in order`() throws {
            let cookie = try RFC_6265.Cookie("SID=31d4d96e407aad42; lang=en-US")
            #expect(
                try cookie.pairs == [
                    .init(name: "SID", value: "31d4d96e407aad42"),
                    .init(name: "lang", value: "en-US"),
                ]
            )
        }

        @Test
        func `serializes pairs joined by the pair delimiter`() throws {
            let cookie = RFC_6265.Cookie(
                pairs: try [
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
        func `lenient parse skips segments without separator`() throws {
            let cookie = RFC_6265.Cookie.parse(skippingInvalidPairs: "a=1; junk; b=2")
            #expect(
                try cookie.pairs == [
                    .init(name: "a", value: "1"),
                    .init(name: "b", value: "2"),
                ]
            )
        }

        @Test
        func `empty value is preserved`() throws {
            let cookie = try RFC_6265.Cookie("a=")
            #expect(try cookie.pairs == [.init(name: "a", value: "")])
            #expect(cookie.headerValue == "a=")
        }

        @Test
        func `empty name is rejected`() {
            #expect(throws: RFC_6265.Cookie.Error.invalidPair("=v", .invalidName(""))) {
                try RFC_6265.Cookie("=v")
            }
        }

        @Test
        func `semicolon without following space is rejected as a value octet`() {
            #expect(
                throws: RFC_6265.Cookie.Error.invalidPair("a=1;b=2", .invalidValue("1;b=2"))
            ) {
                try RFC_6265.Cookie("a=1;b=2")
            }
        }

        @Test(arguments: ["a b", "a;b", "a=b", "a\"b", "a\u{1}b", "", "é"])
        func `a name outside the token grammar is rejected`(_ name: String) {
            #expect(throws: RFC_6265.Cookie.Pair.Error.invalidName(name)) {
                try RFC_6265.Cookie.Pair(name: name, value: "v")
            }
        }

        @Test(arguments: ["1; evil=2", "1;evil=2", "a b", "a,b", "a\\b", "\"a", "a\r\nb", "é"])
        func `a value outside cookie-octet is rejected`(_ value: String) {
            #expect(throws: RFC_6265.Cookie.Pair.Error.invalidValue(value)) {
                try RFC_6265.Cookie.Pair(name: "a", value: value)
            }
        }

        @Test
        func `a decoded pair is held to the grammar`() throws {
            let data = Array(#"{"name":"a","value":"1; evil=2"}"#.utf8)
            #expect(throws: RFC_6265.Cookie.Pair.Error.invalidValue("1; evil=2")) {
                try JSONDecoder().decode(RFC_6265.Cookie.Pair.self, from: Data(data))
            }
        }

        @Test
        func `quoted value is stored verbatim`() throws {
            let cookie = try RFC_6265.Cookie(#"a="quoted""#)
            #expect(try cookie.pairs == [.init(name: "a", value: #""quoted""#)])
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
            #expect(
                RFC_6265.Cookie.parse(skippingInvalidPairs: value)
                    == (try RFC_6265.Cookie.parse(value))
            )
        }
    }
}
