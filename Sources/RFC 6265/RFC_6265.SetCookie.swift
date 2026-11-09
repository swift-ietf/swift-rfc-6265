public import Domain_Standard
public import RFC_3986
import RFC_3986_Foundation_Integration

extension RFC_6265 {

    public struct SetCookie: Sendable {

        public var pair: Cookie.Pair

        // swift-linter:disable:next raw concept
        // REASON: The Expires attribute's text, kept as sent so a Set-Cookie line round-trips; RFC 6265 5.1.1 has user agents parse it leniently and the tests keep expires=now; looked at RFC_3339.DateTime, ISO_8601.DateTime and HTTP.Date, which would lose such values, and none is among this package's dependencies.
        public private(set) var expires: String?

        public var maxAge: Int?

        public var domain: Domain?

        public private(set) var path: RFC_3986.URI.Path?

        public var secure: Bool

        public var httpOnly: Bool

        public private(set) var extensions: [String]

        public init(
            pair: Cookie.Pair,
            // swift-linter:disable:next raw concept
            // REASON: The Expires attribute's text, kept as sent so a Set-Cookie line round-trips; RFC 6265 5.1.1 has user agents parse it leniently and the tests keep expires=now; looked at RFC_3339.DateTime, ISO_8601.DateTime and HTTP.Date, which would lose such values, and none is among this package's dependencies.
            expires: String? = nil,
            maxAge: Int? = nil,
            domain: Domain? = nil,
            path: RFC_3986.URI.Path? = nil,

            secure: Bool = false,

            httpOnly: Bool = false,
            extensions: [String] = []
        ) throws(Error) {
            if let expires, !Self.isAttributeValue(expires) { throw .invalidExpires(expires) }
            if let path, !Self.isAttributeValue(path.description) { throw .invalidPath(path.description) }
            if let invalid = extensions.first(where: { !Self.isAttributeValue($0) }) {
                throw .invalidExtension(invalid)
            }
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
        let pair: RFC_6265.Cookie.Pair
        do throws(RFC_6265.Cookie.Pair.Error) {
            pair = try RFC_6265.Cookie.Pair.parse(Self.trimOWS(first))
        } catch {
            throw .invalidPair(String(first), error)
        }
        var expires: String?
        var maxAge: Int?
        var domain: Domain?
        var path: RFC_3986.URI.Path?
        var secure = false
        var httpOnly = false
        var extensions: [String] = []

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
                expires = String(attributeValue)

            case "max-age":
                let isNegative = attributeValue.first == "-"
                let digits = isNegative ? attributeValue.dropFirst() : attributeValue
                guard !digits.isEmpty, digits.utf8.allSatisfy({ (0x30...0x39).contains($0) }) else {
                    throw .invalidMaxAge(String(attributeValue))
                }
                maxAge = Int(attributeValue) ?? (isNegative ? Int.min : Int.max)

            case "domain":
                domain = try? Domain(attributeValue.first == "." ? attributeValue.dropFirst() : attributeValue)

            case "path":
                if attributeValue.first == "/", let candidate = try? RFC_3986.URI.Path(attributeValue),
                    Self.isAttributeValue(candidate.description)
                {
                    path = candidate
                } else {
                    path = nil
                }

            case "secure" where parts.count == 1:
                secure = true

            case "httponly" where parts.count == 1:
                httpOnly = true

            default:
                extensions.append(String(attribute))
            }
        }
        try self.init(
            pair: pair,
            expires: expires,
            maxAge: maxAge,
            domain: domain,
            path: path,
            secure: secure,
            httpOnly: httpOnly,
            extensions: extensions
        )
    }

    private enum CodingKeys: String, CodingKey {
        case pair
        case expires
        case maxAge
        case domain
        case path
        case secure
        case httpOnly
        case extensions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            pair: try container.decode(RFC_6265.Cookie.Pair.self, forKey: .pair),
            expires: try container.decodeIfPresent(String.self, forKey: .expires),
            maxAge: try container.decodeIfPresent(Int.self, forKey: .maxAge),
            domain: try container.decodeIfPresent(Domain.self, forKey: .domain),
            path: try container.decodeIfPresent(RFC_3986.URI.Path.self, forKey: .path),
            secure: try container.decode(Bool.self, forKey: .secure),
            httpOnly: try container.decode(Bool.self, forKey: .httpOnly),
            extensions: try container.decode([String].self, forKey: .extensions)
        )
    }

    private static func isAttributeValue(_ value: some StringProtocol) -> Bool {
        value.utf8.allSatisfy { byte in (0x20...0x7E).contains(byte) && byte != 0x3B }
    }

    private static func trimOWS(_ value: Substring) -> Substring {
        var result = value
        while result.first == " " || result.first == "\t" { result = result.dropFirst() }
        while result.last == " " || result.last == "\t" { result = result.dropLast() }
        return result
    }
}
