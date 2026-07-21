extension RFC_6265.Cookie.Pair {
    /// Errors that can occur while parsing a `cookie-pair`
    /// (RFC 6265 Section 4.1.1).
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The segment contains no `=` separating cookie-name from
        /// cookie-value.
        case missingNameValueSeparator(String)
    }
}

// MARK: - CustomStringConvertible

extension RFC_6265.Cookie.Pair.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .missingNameValueSeparator(let segment):
            return "Cookie pair '\(segment)' has no '=' separating name and value (RFC 6265 §4.1.1)"
        }
    }
}
