extension RFC_6265 {
    /// The `Set-Cookie` response header value defined by RFC 6265 Section 4.1.
    ///
    /// ## Grammar (RFC 6265 Section 4.1.1)
    ///
    /// ```
    /// set-cookie-header = "Set-Cookie:" SP set-cookie-string
    /// set-cookie-string = cookie-pair *( ";" SP cookie-av )
    /// cookie-av         = expires-av / max-age-av / domain-av /
    ///                     path-av / secure-av / httponly-av /
    ///                     extension-av
    /// ```
    public struct SetCookie: Sendable {
        /// The cookie pair (`cookie-name "=" cookie-value`).
        public var pair: Cookie.Pair

        /// The `Expires` attribute value (`sane-cookie-date`), kept as the
        /// raw date string. Date interpretation is a user-agent concern
        /// (RFC 6265 Section 5.1.1) and outside this grammar.
        public var expires: String?

        /// The `Max-Age` attribute value, in seconds.
        public var maxAge: Int?

        /// The `Domain` attribute value.
        public var domain: String?

        /// The `Path` attribute value.
        public var path: String?

        /// Whether the `Secure` attribute is present.
        public var secure: Bool

        /// Whether the `HttpOnly` attribute is present.
        public var httpOnly: Bool

        /// Any `extension-av` attributes, in order of appearance.
        public var extensions: [String]

        /// Creates a `Set-Cookie` value.
        public init(
            pair: Cookie.Pair,
            expires: String? = nil,
            maxAge: Int? = nil,
            domain: String? = nil,
            path: String? = nil,
            // swift-linter:disable:next bool public parameter
            // REASON: memberwise initializer of a Codable wire-schema type (#16 Option C
            // ledger, Entry II.3) — mirrors the RFC 6265 `Secure` presence flag verbatim.
            secure: Bool = false,
            // swift-linter:disable:next bool public parameter
            // REASON: memberwise initializer of a Codable wire-schema type (#16 Option C
            // ledger, Entry II.3) — mirrors the RFC 6265 `HttpOnly` presence flag verbatim.
            httpOnly: Bool = false,
            extensions: [String] = []
        ) {
            self.pair = pair
            self.expires = expires
            self.maxAge = maxAge
            self.domain = domain
            self.path = path
            self.secure = secure
            self.httpOnly = httpOnly
            self.extensions = extensions
        }
    }
}

extension RFC_6265.SetCookie: Codable, Equatable, Hashable, CustomStringConvertible {
    /// The canonical `Set-Cookie` header field value.
    ///
    /// Attributes are serialized in the Section 4.1.1 `cookie-av` order:
    /// `Expires`, `Max-Age`, `Domain`, `Path`, `Secure`, `HttpOnly`,
    /// then extension attributes.
    public var headerValue: String {
        var components = [pair.serialized]
        if let expires { components.append("Expires=\(expires)") }
        if let maxAge { components.append("Max-Age=\(maxAge)") }
        if let domain { components.append("Domain=\(domain)") }
        if let path { components.append("Path=\(path)") }
        if secure { components.append("Secure") }
        if httpOnly { components.append("HttpOnly") }
        components.append(contentsOf: extensions)
        return components.joined(separator: "; ")
    }

    public var description: String { headerValue }

    /// Parses an RFC 6265 `Set-Cookie` header field value.
    ///
    /// The first `;`-separated segment must be a cookie pair; the remaining
    /// segments are cookie attributes. Attribute names are matched
    /// case-insensitively per Section 5.2; unknown attributes are collected
    /// as ``extensions``. When an attribute occurs more than once, the last
    /// occurrence wins (Section 5.3).
    ///
    /// - Throws: ``Error`` when the cookie pair is missing or `Max-Age`
    ///   is not a valid integer.
    public static func parse(_ value: some StringProtocol) throws(Error) -> Self {
        try Self(value)
    }

    /// Creates a `Set-Cookie` value by parsing its header field value.
    ///
    /// - Throws: ``Error`` when the cookie pair is missing or `Max-Age`
    ///   is not a valid integer.
    public init(_ value: some StringProtocol) throws(Error) {
        guard !value.isEmpty else { throw .emptySetCookieString }
        let string = String(value)[...]
        var segments = string.split(separator: ";", omittingEmptySubsequences: false)[...]

        guard let first = segments.popFirst() else { throw .emptySetCookieString }
        var setCookie: Self
        do throws(RFC_6265.Cookie.Pair.Error) {
            setCookie = Self(pair: try RFC_6265.Cookie.Pair.parse(Self.trimOWS(first)))
        } catch {
            throw .invalidPair(String(first), error)
        }

        for segment in segments {
            let attribute = Self.trimOWS(segment)
            let parts = attribute.split(
                separator: "=",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            let attributeValue = parts.count == 2 ? Self.trimOWS(parts[1]) : ""

            switch Self.trimOWS(parts[0]).lowercased() {
            case "expires":
                setCookie.expires = String(attributeValue)

            case "max-age":
                guard let seconds = Int(attributeValue) else {
                    throw .invalidMaxAge(String(attributeValue))
                }
                setCookie.maxAge = seconds

            case "domain":
                setCookie.domain = String(attributeValue)

            case "path":
                setCookie.path = String(attributeValue)

            case "secure" where parts.count == 1:
                setCookie.secure = true

            case "httponly" where parts.count == 1:
                setCookie.httpOnly = true

            default:
                setCookie.extensions.append(String(attribute))
            }
        }
        self = setCookie
    }

    /// Trims optional whitespace (SP / HTAB) from both ends of a segment.
    private static func trimOWS(_ value: Substring) -> Substring {
        var result = value
        while result.first == " " || result.first == "\t" { result = result.dropFirst() }
        while result.last == " " || result.last == "\t" { result = result.dropLast() }
        return result
    }
}
