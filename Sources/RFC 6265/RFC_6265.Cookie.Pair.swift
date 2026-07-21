extension RFC_6265.Cookie {
    /// A cookie pair defined by RFC 6265 Section 4.1.1.
    ///
    /// ## Grammar (RFC 6265 Section 4.1.1)
    ///
    /// ```
    /// cookie-pair  = cookie-name "=" cookie-value
    /// cookie-name  = token
    /// cookie-value = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
    /// ```
    ///
    /// The pair is structural: `name` is everything before the first `=`
    /// and `value` is everything after it. The value may be empty.
    public struct Pair: Sendable {
        /// The cookie name.
        public var name: String

        /// The cookie value.
        ///
        /// Stored exactly as it appears on the wire, including surrounding
        /// DQUOTEs when present.
        public var value: String

        /// Creates a cookie pair.
        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }
}

extension RFC_6265.Cookie.Pair: Codable, Equatable, Hashable, CustomStringConvertible {
    /// The serialized `cookie-pair`: `name=value`.
    public var serialized: String { "\(name)=\(value)" }

    public var description: String { serialized }

    /// Parses a single `cookie-pair`.
    ///
    /// The pair is split on the first `=`; any further `=` characters
    /// belong to the value.
    ///
    /// - Throws: ``Error`` when the segment contains no `=` separator.
    public static func parse(_ segment: some StringProtocol) throws(Error) -> Self {
        guard let separator = segment.firstIndex(of: "=") else {
            throw .missingNameValueSeparator(String(segment))
        }
        return Self(
            name: String(segment[..<separator]),
            value: String(segment[segment.index(after: separator)...])
        )
    }

    /// Creates a cookie pair by parsing a `cookie-pair` string.
    public init(_ segment: String) throws(Error) {
        self = try Self.parse(segment)
    }
}
