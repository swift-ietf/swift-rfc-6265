extension RFC_6265.Cookie {

    public struct Pair: Sendable {

        public var name: String

        public var value: String

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }
}

extension RFC_6265.Cookie.Pair: Codable, Equatable, Hashable, CustomStringConvertible {

    public var serialized: String { "\(name)=\(value)" }

    public var description: String { serialized }

    public static func parse(_ segment: some StringProtocol) throws(Error) -> Self {
        try Self(segment)
    }

    public init(_ segment: some StringProtocol) throws(Error) {
        guard let separator = segment.firstIndex(of: "=") else {
            throw .missingNameValueSeparator(String(segment))
        }
        self.name = String(segment[..<separator])
        self.value = String(segment[segment.index(after: separator)...])
    }
}
