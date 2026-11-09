extension RFC_6265.SetCookie {

    public enum Error: Swift::Error, Sendable, Equatable {

        case emptySetCookieString

        case invalidPair(String, RFC_6265.Cookie.Pair.Error)

        case invalidMaxAge(String)

        case invalidExpires(String)

        case invalidPath(String)

        case invalidExtension(String)
    }
}

extension RFC_6265.SetCookie.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptySetCookieString:
            return "Set-Cookie string is empty; RFC 6265 §4.1.1 requires a cookie pair"

        case .invalidPair(let segment, let error):
            return "Set-Cookie segment '\(segment)' is not a cookie pair: \(error)"

        case .invalidMaxAge(let value):
            return "Set-Cookie Max-Age value '\(value)' is not a valid integer (RFC 6265 §4.1.1)"

        case .invalidExpires(let value):
            return "Set-Cookie Expires value '\(value)' holds a ';' or a control character (RFC 6265 §4.1.1)"

        case .invalidPath(let value):
            return "Set-Cookie Path value '\(value)' holds a ';' or a control character (RFC 6265 §4.1.1 path-value)"

        case .invalidExtension(let value):
            return "Set-Cookie extension '\(value)' holds a ';' or a control character (RFC 6265 §4.1.1 extension-av)"
        }
    }
}
