# swift-rfc-6265

Use this package when you need to read or write the Cookie request header or a Set-Cookie response header as text. Start from `RFC_6265.Cookie` for a Cookie header and from `RFC_6265.SetCookie` for a Set-Cookie header. It doesn't store cookies, match them to requests or check dates, domains or paths. For a cookie toolkit built on top of it, use swift-http-cookies.

## Laws

- In a Cookie header, pairs are separated only by a semicolon followed by a space. `a=1;b=2` is one pair whose value is `1;b=2`.
- A pair splits at its first `=`. The name and value are kept exactly as written, so an empty name, an empty value, quotes and further `=` signs all survive a round trip.
- `RFC_6265.Cookie.init(_:)` fails on an empty string or on any segment without `=`. `RFC_6265.Cookie.parse(skippingInvalidPairs:)` never fails and drops those segments.
- A Set-Cookie header is split at every semicolon, and spaces and tabs are trimmed around each part, around attribute names and around attribute values.
- The first part of a Set-Cookie header must be a pair. Attribute names match case-insensitively, and when an attribute repeats, the last one wins.
- `Expires`, `Domain` and `Path` are kept as text, with no checks.
- `Max-Age` must be an optional `-` followed by digits, or parsing fails. A value too large or too small for `Int` becomes `Int.max` or `Int.min`.
- `Secure` and `HttpOnly` count only without a value. With a value, and for any unknown attribute, the trimmed text goes to `RFC_6265.SetCookie.extensions` in order.
- `RFC_6265.SetCookie.headerValue` writes the pair, then `Expires`, `Max-Age`, `Domain`, `Path`, `Secure`, `HttpOnly`, then the extensions, separated by a semicolon and a space.
