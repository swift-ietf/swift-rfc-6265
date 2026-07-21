extension RFC_6265.SetCookie {
    /// Errors that can occur while parsing a `set-cookie-string`
    /// (RFC 6265 Section 4.1.1).
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The set-cookie string is empty.
        case emptySetCookieString

        /// The leading segment is not a well-formed cookie pair.
        case invalidPair(String, RFC_6265.Cookie.Pair.Error)

        /// The `Max-Age` attribute value is not a valid integer.
        case invalidMaxAge(String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_6265.SetCookie.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptySetCookieString:
            return "Set-Cookie string is empty; RFC 6265 §4.1.1 requires a cookie pair"
        case .invalidPair(let segment, let error):
            return "Set-Cookie segment '\(segment)' is not a cookie pair: \(error)"
        case .invalidMaxAge(let value):
            return "Set-Cookie Max-Age value '\(value)' is not a valid integer (RFC 6265 §4.1.1)"
        }
    }
}
