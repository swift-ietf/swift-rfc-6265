extension RFC_6265.Cookie {
    /// Errors that can occur while parsing a `cookie-string`
    /// (RFC 6265 Section 4.2.1).
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The cookie string is empty; the grammar requires at least one
        /// cookie pair.
        case emptyCookieString

        /// A `"; "`-separated segment is not a well-formed cookie pair.
        case invalidPair(String, Pair.Error)
    }
}

// MARK: - CustomStringConvertible

extension RFC_6265.Cookie.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyCookieString:
            return "Cookie string is empty; RFC 6265 §4.2.1 requires at least one cookie pair"
        case .invalidPair(let segment, let error):
            return "Cookie string segment '\(segment)' is invalid: \(error)"
        }
    }
}
