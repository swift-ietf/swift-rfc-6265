# swift-rfc-6265

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift namespace types for RFC 6265: HTTP State Management Mechanism

## Overview

This package provides Swift namespace types for HTTP cookies as defined in [RFC 6265](https://www.rfc-editor.org/rfc/rfc6265.html). This package defines the RFC 6265 namespace enum and Cookie type for extension by parser implementations.

## Features

- ✅ RFC 6265 namespace enum
- ✅ Cookie type for parser extensions
- ✅ Swift 6 strict concurrency support
- ✅ Full `Sendable` conformance

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-6265.git", from: "0.2.2")
]
```

## Usage

This package provides namespace types that are extended by parser implementations (e.g., swift-url-routing):

```swift
import RFC_6265

// Parser implementations extend RFC_6265.Cookie
extension RFC_6265.Cookie {
  public struct Parser<FieldParsers>: ParserPrinter { ... }
}
```

## Related Packages

- [swift-url-routing](https://github.com/pointfreeco/swift-url-routing) - Provides parser implementations

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
