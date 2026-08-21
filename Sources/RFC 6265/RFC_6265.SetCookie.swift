extension RFC_6265 {

    public struct SetCookie: Sendable {

        public var pair: Cookie.Pair

        public var expires: String?

        public var maxAge: Int?

        public var domain: String?

        public var path: String?

        public var secure: Bool

        public var httpOnly: Bool

        public var extensions: [String]

        public init(
            pair: Cookie.Pair,
            expires: String? = nil,
            maxAge: Int? = nil,
            domain: String? = nil,
            path: String? = nil,

            secure: Bool = false,

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

    public static func parse(_ value: some StringProtocol) throws(Error) -> Self {
        try Self(value)
    }

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

    private static func trimOWS(_ value: Substring) -> Substring {
        var result = value
        while result.first == " " || result.first == "\t" { result = result.dropFirst() }
        while result.last == " " || result.last == "\t" { result = result.dropLast() }
        return result
    }
}
