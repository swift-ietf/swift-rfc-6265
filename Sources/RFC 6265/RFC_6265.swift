/// RFC 6265: HTTP State Management Mechanism
///
/// This module implements the HTTP cookie grammar as specified in RFC 6265:
/// the `Set-Cookie` response header (Section 4.1) and the `Cookie` request
/// header (Section 4.2).
///
/// Example usage:
/// ```swift
/// let cookie = try RFC_6265.Cookie("SID=31d4d96e407aad42; lang=en-US")
/// let setCookie = try RFC_6265.SetCookie("SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
/// ```
public enum RFC_6265 {}
