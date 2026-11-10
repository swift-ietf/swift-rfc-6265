public import RFC_9110

extension RFC_9110.Field.Name {

    public static var cookie: Self { Self(unchecked: "Cookie") }

    public static var setCookie: Self { Self(unchecked: "Set-Cookie") }
}
