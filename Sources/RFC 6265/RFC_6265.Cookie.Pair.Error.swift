extension RFC_6265.Cookie.Pair {

    public enum Error: Swift::Error, Sendable, Equatable {

        case missingNameValueSeparator(String)

        case invalidName(String)

        case invalidValue(String)
    }
}

extension RFC_6265.Cookie.Pair.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .missingNameValueSeparator(let segment):
            return "Cookie pair '\(segment)' has no '=' separating name and value (RFC 6265 §4.1.1)"

        case .invalidName(let name):
            return "Cookie name '\(name)' is not a token (RFC 6265 §4.1.1 cookie-name)"

        case .invalidValue(let value):
            return "Cookie value '\(value)' holds a character outside cookie-octet (RFC 6265 §4.1.1 cookie-value)"
        }
    }
}
