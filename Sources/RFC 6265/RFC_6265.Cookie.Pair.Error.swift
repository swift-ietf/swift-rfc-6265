extension RFC_6265.Cookie.Pair {

    public enum Error: Swift.Error, Sendable, Equatable {

        case missingNameValueSeparator(String)
    }
}

extension RFC_6265.Cookie.Pair.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .missingNameValueSeparator(let segment):
            return "Cookie pair '\(segment)' has no '=' separating name and value (RFC 6265 §4.1.1)"
        }
    }
}
