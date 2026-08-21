extension RFC_6265 {

    public struct Cookie: Sendable {

        public var pairs: [Pair]

        public init(pairs: [Pair]) {
            self.pairs = pairs
        }
    }
}

extension RFC_6265.Cookie: Codable, Equatable, Hashable, CustomStringConvertible {

    public var headerValue: String {
        pairs.map(\.serialized).joined(separator: "; ")
    }

    public var description: String { headerValue }

    public static func parse(_ value: some StringProtocol) throws(Error) -> Self {
        try Self(value)
    }

    public static func parse(skippingInvalidPairs value: some StringProtocol) -> Self {
        var pairs: [Pair] = []
        for segment in Self.pairSegments(of: String(value)[...]) {
            let pair: Pair
            do throws(Pair.Error) {
                pair = try Pair.parse(segment)
            } catch {
                continue
            }
            pairs.append(pair)
        }
        return Self(pairs: pairs)
    }

    public init(_ value: some StringProtocol) throws(Error) {
        guard !value.isEmpty else { throw .emptyCookieString }

        var pairs: [Pair] = []
        for segment in Self.pairSegments(of: String(value)[...]) {
            do throws(Pair.Error) {
                pairs.append(try Pair.parse(segment))
            } catch {
                throw .invalidPair(String(segment), error)
            }
        }
        self.pairs = pairs
    }

    private static func pairSegments(of value: Substring) -> [Substring] {
        var segments: [Substring] = []
        var remainder = value
        while let range = remainder.firstRange(of: "; ") {
            segments.append(remainder[..<range.lowerBound])
            remainder = remainder[range.upperBound...]
        }
        segments.append(remainder)
        return segments
    }
}
