extension RFC_6265 {
    /// The `Cookie` request header value defined by RFC 6265 Section 4.2.
    ///
    /// ## Grammar (RFC 6265 Section 4.2.1)
    ///
    /// ```
    /// cookie-header = "Cookie:" OWS cookie-string OWS
    /// cookie-string = cookie-pair *( ";" SP cookie-pair )
    /// ```
    ///
    /// A `Cookie` value is an ordered list of cookie pairs, separated by
    /// the literal two-character delimiter `"; "`.
    public struct Cookie: Sendable {
        /// The cookie pairs, in the order they appear in the cookie string.
        public var pairs: [Pair]

        /// Creates a `Cookie` value from cookie pairs.
        public init(pairs: [Pair]) {
            self.pairs = pairs
        }
    }
}

extension RFC_6265.Cookie: Codable, Equatable, Hashable, CustomStringConvertible {
    /// The canonical `Cookie` header field value.
    ///
    /// Pairs are serialized as `name=value`, joined by `"; "` per the
    /// Section 4.2.1 grammar.
    public var headerValue: String {
        pairs.map(\.serialized).joined(separator: "; ")
    }

    public var description: String { headerValue }

    /// Parses an RFC 6265 `Cookie` header field value.
    ///
    /// Every `"; "`-separated segment must be a well-formed cookie pair
    /// (contain a `=` separator); otherwise the whole cookie string is
    /// rejected.
    ///
    /// - Throws: ``Error`` when the cookie string is empty or a segment
    ///   is not a cookie pair.
    public static func parse(_ value: some StringProtocol) throws(Error) -> Self {
        try Self(value)
    }

    /// Parses a `Cookie` header field value, skipping malformed segments.
    ///
    /// This is the tolerant reading of the Section 4.2.1 grammar: segments
    /// that are not cookie pairs (no `=` separator) are dropped rather than
    /// rejecting the whole cookie string. It reproduces the recovery
    /// behavior expected of header-processing pipelines.
    public static func parse(skippingInvalidPairs value: some StringProtocol) -> Self {
        var pairs: [Pair] = []
        for segment in Self.pairSegments(of: String(value)[...]) {
            let pair: Pair
            do throws(Pair.Error) {
                pair = try Pair.parse(segment)
            } catch {
                continue
            }
            pairs.append(pair)
        }
        return Self(pairs: pairs)
    }

    /// Creates a `Cookie` value by parsing a `Cookie` header field value.
    ///
    /// - Throws: ``Error`` when the cookie string is empty or a segment
    ///   is not a cookie pair.
    public init(_ value: some StringProtocol) throws(Error) {
        guard !value.isEmpty else { throw .emptyCookieString }

        var pairs: [Pair] = []
        for segment in Self.pairSegments(of: String(value)[...]) {
            do throws(Pair.Error) {
                pairs.append(try Pair.parse(segment))
            } catch {
                throw .invalidPair(String(segment), error)
            }
        }
        self.pairs = pairs
    }

    /// Splits a cookie-string on the literal `"; "` pair delimiter
    /// (RFC 6265 Section 4.2.1: `cookie-pair *( ";" SP cookie-pair )`).
    private static func pairSegments(of value: Substring) -> [Substring] {
        var segments: [Substring] = []
        var remainder = value
        while let range = remainder.firstRange(of: "; ") {
            segments.append(remainder[..<range.lowerBound])
            remainder = remainder[range.upperBound...]
        }
        segments.append(remainder)
        return segments
    }
}
