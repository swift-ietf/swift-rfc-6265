# swift-rfc-6265

Use this package when you need to read or write the Cookie request header or a Set-Cookie response header as text. Start from `RFC_6265.Cookie` for a Cookie header and from `RFC_6265.SetCookie` for a Set-Cookie header. It doesn't store cookies, match them to requests or check dates, domains or paths. For a cookie toolkit built on top of it, use swift-http-cookies.

## Laws

- `RFC_9110.Field.Name.cookie` and `.setCookie` are the two field names RFC 6265 registers, spelled `Cookie` and `Set-Cookie`.
- In a Cookie header, pairs are separated only by a semicolon followed by a space. In `a=1;b=2` the value `1;b=2` holds a semicolon, so the pair is invalid.
- A pair splits at its first `=`. The name must be an RFC 6265 `cookie-name` token and the value a `cookie-value` (cookie-octets, optionally in double quotes); `RFC_6265.Cookie.Pair.init(name:value:)` and decoding refuse anything else, so no pair can write a `;`, space, comma or control character into a header. An empty value, quotes and further `=` signs in the value survive a round trip.
- `RFC_6265.Cookie.init(_:)` fails on an empty string or on any segment that is not a valid pair. `RFC_6265.Cookie.parse(skippingInvalidPairs:)` never fails and drops those segments.
- A Set-Cookie header is split at every semicolon, and spaces and tabs are trimmed around each part, around attribute names and around attribute values.
- The first part of a Set-Cookie header must be a pair. Attribute names match case-insensitively, and when an attribute repeats, the last one wins.
- `Expires` is kept as text. `Domain` is read as a `Domain`, ignoring a leading dot, and `Path` as an `RFC_3986.URI.Path`; a value that holds neither leaves the attribute unset, as RFC 6265 Sections 5.2.3 and 5.2.4 say.
- `Expires`, `Path` and every extension may hold only printable ASCII other than `;` (RFC 6265 Section 4.1.1). `RFC_6265.SetCookie.init(pair:expires:maxAge:domain:path:secure:httpOnly:extensions:)`, parsing and decoding refuse anything else, and those three properties can only be set through them, so a Set-Cookie value cannot gain an attribute it was not given. A `Path` that breaks the rule reads as unset when parsed.
- `Max-Age` must be an optional `-` followed by digits, or parsing fails. A value too large or too small for `Int` becomes `Int.max` or `Int.min`.
- `Secure` and `HttpOnly` count only without a value. With a value, and for any unknown attribute, the trimmed text goes to `RFC_6265.SetCookie.extensions` in order.
- `RFC_6265.SetCookie.headerValue` writes the pair, then `Expires`, `Max-Age`, `Domain`, `Path`, `Secure`, `HttpOnly`, then the extensions, separated by a semicolon and a space.
