extension RFC_6265.Cookie {

    public struct Pair: Sendable {

        public let name: String

        public let value: String

        public init(name: String, value: String) throws(Error) {
            guard Self.isToken(name) else { throw .invalidName(name) }
            guard Self.isCookieValue(value) else { throw .invalidValue(value) }
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
        try self.init(
            name: String(segment[..<separator]),
            value: String(segment[segment.index(after: separator)...])
        )
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            name: try container.decode(String.self, forKey: .name),
            value: try container.decode(String.self, forKey: .value)
        )
    }
}

extension RFC_6265.Cookie.Pair {

    private static func isToken(_ name: String) -> Bool {
        !name.isEmpty
            && name.utf8.allSatisfy { byte in
                (0x21...0x7E).contains(byte) && !#"()<>@,;:\"/[]?={}"#.utf8.contains(byte)
            }
    }

    private static func isCookieValue(_ value: String) -> Bool {
        var octets = value.utf8[...]
        if octets.count >= 2, octets.first == 0x22, octets.last == 0x22 {
            octets = octets.dropFirst().dropLast()
        }
        return octets.allSatisfy { byte in
            byte == 0x21
                || (0x23...0x2B).contains(byte)
                || (0x2D...0x3A).contains(byte)
                || (0x3C...0x5B).contains(byte)
                || (0x5D...0x7E).contains(byte)
        }
    }
}
