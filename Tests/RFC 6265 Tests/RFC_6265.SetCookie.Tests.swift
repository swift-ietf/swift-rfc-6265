import Testing

@testable import RFC_6265

struct RFC_6265_SetCookie_Tests {}

extension RFC_6265_SetCookie_Tests {
    @Suite
    struct Unit {
        @Test
        func `parses a bare cookie pair`() throws {
            let setCookie = try RFC_6265.SetCookie("SID=31d4d96e407aad42")
            #expect(setCookie.pair == .init(name: "SID", value: "31d4d96e407aad42"))
            #expect(setCookie.expires == nil)
            #expect(setCookie.maxAge == nil)
            #expect(setCookie.domain == nil)
            #expect(setCookie.path == nil)
            #expect(setCookie.secure == false)
            #expect(setCookie.httpOnly == false)
            #expect(setCookie.extensions.isEmpty)
        }

        @Test
        func `parses the RFC 6265 Section 3 examples`() throws {
            let first = try RFC_6265.SetCookie("SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
            #expect(first.pair == .init(name: "SID", value: "31d4d96e407aad42"))
            #expect(first.path == "/")
            #expect(first.secure == true)
            #expect(first.httpOnly == true)

            let second = try RFC_6265.SetCookie("SID=31d4d96e407aad42; Path=/; Domain=example.com")
            #expect(second.path == "/")
            #expect(second.domain == "example.com")

            let third = try RFC_6265.SetCookie(
                "lang=en-US; Expires=Wed, 09 Jun 2021 10:18:14 GMT"
            )
            #expect(third.pair == .init(name: "lang", value: "en-US"))
            #expect(third.expires == "Wed, 09 Jun 2021 10:18:14 GMT")
        }

        @Test
        func `parses Max-Age as an integer`() throws {
            let setCookie = try RFC_6265.SetCookie("id=1; Max-Age=3600")
            #expect(setCookie.maxAge == 3600)
        }

        @Test
        func `serializes attributes in grammar order`() {
            let setCookie = RFC_6265.SetCookie(
                pair: .init(name: "SID", value: "31d4d96e407aad42"),
                expires: "Wed, 09 Jun 2021 10:18:14 GMT",
                maxAge: 3600,
                domain: "example.com",
                path: "/",
                secure: true,
                httpOnly: true,
                extensions: ["SameSite=Lax"]
            )
            #expect(
                setCookie.headerValue == "SID=31d4d96e407aad42; "
                    + "Expires=Wed, 09 Jun 2021 10:18:14 GMT; Max-Age=3600; "
                    + "Domain=example.com; Path=/; Secure; HttpOnly; SameSite=Lax"
            )
            #expect(setCookie.description == setCookie.headerValue)
        }
    }

    @Suite
    struct `Edge Case` {
        @Test
        func `empty set-cookie string throws`() {
            #expect(throws: RFC_6265.SetCookie.Error.emptySetCookieString) {
                try RFC_6265.SetCookie.parse("")
            }
        }

        @Test
        func `missing cookie pair throws`() {
            #expect(
                throws: RFC_6265.SetCookie.Error.invalidPair(
                    "Secure",
                    .missingNameValueSeparator("Secure")
                )
            ) {
                try RFC_6265.SetCookie.parse("Secure; HttpOnly")
            }
        }

        @Test
        func `non-numeric Max-Age throws`() {
            #expect(throws: RFC_6265.SetCookie.Error.invalidMaxAge("soon")) {
                try RFC_6265.SetCookie.parse("id=1; Max-Age=soon")
            }
        }

        @Test
        func `negative Max-Age is accepted`() throws {
            let setCookie = try RFC_6265.SetCookie("id=1; Max-Age=-1")
            #expect(setCookie.maxAge == -1)
        }

        @Test
        func `attribute names match case-insensitively`() throws {
            let setCookie = try RFC_6265.SetCookie(
                "id=1; expires=now; MAX-AGE=1; domain=example.com; PATH=/; secure; HTTPONLY"
            )
            #expect(setCookie.expires == "now")
            #expect(setCookie.maxAge == 1)
            #expect(setCookie.domain == "example.com")
            #expect(setCookie.path == "/")
            #expect(setCookie.secure == true)
            #expect(setCookie.httpOnly == true)
        }

        @Test
        func `last occurrence of a repeated attribute wins`() throws {
            let setCookie = try RFC_6265.SetCookie("id=1; Path=/a; Path=/b")
            #expect(setCookie.path == "/b")
        }

        @Test
        func `unknown attributes are collected as extensions`() throws {
            let setCookie = try RFC_6265.SetCookie("id=1; SameSite=Strict; Partitioned")
            #expect(setCookie.extensions == ["SameSite=Strict", "Partitioned"])
        }

        @Test
        func `known attribute with unexpected value form falls to extensions`() throws {
            let setCookie = try RFC_6265.SetCookie("id=1; Secure=verily")
            #expect(setCookie.secure == false)
            #expect(setCookie.extensions == ["Secure=verily"])
        }

        @Test
        func `optional whitespace around attributes is trimmed`() throws {
            let setCookie = try RFC_6265.SetCookie("  id=1 ;  Path = /  ; Secure ")
            #expect(setCookie.pair == .init(name: "id", value: "1"))
            #expect(setCookie.path == "/")
            #expect(setCookie.secure == true)
        }
    }

    @Suite
    struct Integration {
        @Test
        func `set-cookie value round-trips through parse and serialize`() throws {
            let value = "SID=31d4d96e407aad42; Expires=Wed, 09 Jun 2021 10:18:14 GMT; "
                + "Max-Age=3600; Domain=example.com; Path=/; Secure; HttpOnly; SameSite=Lax"
            let setCookie = try RFC_6265.SetCookie(value)
            #expect(setCookie.headerValue == value)
            #expect(try RFC_6265.SetCookie(setCookie.headerValue) == setCookie)
        }

        @Test
        func `set-cookie pair round-trips into a Cookie header pair`() throws {
            let setCookie = try RFC_6265.SetCookie("SID=31d4d96e407aad42; Path=/; Secure")
            let cookie = RFC_6265.Cookie(pairs: [setCookie.pair])
            #expect(cookie.headerValue == "SID=31d4d96e407aad42")
        }
    }
}
