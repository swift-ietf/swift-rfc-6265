extension RFC_6265.Cookie {

    public enum Error: Swift.Error, Sendable, Equatable {

        case emptyCookieString

        case invalidPair(String, Pair.Error)
    }
}

extension RFC_6265.Cookie.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyCookieString:
            return "Cookie string is empty; RFC 6265 §4.2.1 requires at least one cookie pair"

        case .invalidPair(let segment, let error):
            return "Cookie string segment '\(segment)' is invalid: \(error)"
        }
    }
}
