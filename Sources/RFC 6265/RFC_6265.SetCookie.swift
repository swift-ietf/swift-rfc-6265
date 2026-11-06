public import Domain_Standard
public import RFC_3986
import RFC_3986_Foundation_Integration

extension RFC_6265 {

    public struct SetCookie: Sendable {

        public var pair: Cookie.Pair

        public var expires: String?

        public var maxAge: Int?

        public var domain: Domain?

        public var path: RFC_3986.URI.Path?

        public var secure: Bool

        public var httpOnly: Bool

        public var extensions: [String]

        public init(
            pair: Cookie.Pair,
            expires: String? = nil,
            maxAge: Int? = nil,
            domain: Domain? = nil,
            path: RFC_3986.URI.Path? = nil,

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
                let isNegative = attributeValue.first == "-"
                let digits = isNegative ? attributeValue.dropFirst() : attributeValue
                guard !digits.isEmpty, digits.utf8.allSatisfy({ (0x30...0x39).contains($0) }) else {
                    throw .invalidMaxAge(String(attributeValue))
                }
                setCookie.maxAge = Int(attributeValue) ?? (isNegative ? Int.min : Int.max)

            case "domain":
                setCookie.domain = try? Domain(attributeValue.first == "." ? attributeValue.dropFirst() : attributeValue)

            case "path":
                setCookie.path = attributeValue.first == "/" ? (try? RFC_3986.URI.Path(attributeValue)) : nil

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
