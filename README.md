# URI - Uniform Resource Identifier

Swift implementation of a URI in accordance with [RFC3986](https://tools.ietf.org/html/rfc3986).

The implementation hardly tries to be correct and efficient. It uses COW (copy on write) for `URI` and
`URI.HTTP` similiary to `String` and `Array` implementations. A URI and its components are validated
on initialization.

## Synopsis

```swift
var uri: URI = "http://example.com/%D0%BF%D1%83%D1%82%D1%8C/%D0%B4%D0%BE/resource?p1=v1&%D0%BF2=%D0%B72"

print(uri.host ?? "nil") // example.com
print(uri.path) // /%D0%BF%D1%83%D1%82%D1%8C/%D0%B4%D0%BE/resource

for s in uri.path.segments {
	print(s)
}
// путь
// до
// resource

print(uri.query ?? "nil") // p1=v1&%D0%BF2=%D0%B72

for (name, value) in uri.query?.params ?? [:] {
	print("N: \(name), V: \(value)")
}
// N: p1, V: v1
// N: п2, V: з2

uri.host = "mail.ru"
uri.path.segments.append("child")
uri.query?.params["p3"] = "v3"

print(uri) // http://mail.ru/%D0%BF%D1%83%D1%82%D1%8C/%D0%B4%D0%BE/resource/child?p1=v1&%D0%BF2=%D0%B72&p3=v3
```

## Public API

### URI

Generic URI implemented in accordance with [RFC3986](https://tools.ietf.org/html/rfc3986).

```swift
struct URI : URIProtocol {
	init(_ uri: String) throws
	init(_ uri: URI.HTTP)
	init(scheme: URIScheme, userinfo: URIUserinfo? = nil, host: URIHost? = nil, port: UInt? = nil, path: URIPath, query: URIQuery? = nil, fragment: URIFragment? = nil) throws
	var scheme: URIScheme { get set }
	var opaque: String { get }
	var authority: String? { get }
	var userinfo: URIUserinfo? { get set }
	var host: URIHost? { get set }
	var port: UInt? { get set }
	var path: URIPath { get set }
	var query: URIQuery? { get set }
	var fragment: URIFragment? { get set }
	func normalized() -> URI
	var description: String
	init(stringLiteral: String)
	static func == (lhs: Self, rhs: Self) -> Bool
}
```

### URI.HTTP

Implementation of HTTP URI in accordance with [RFC7230, section 2.7](https://tools.ietf.org/html/rfc7230#section-2.7).

```swift
struct URI.HTTP : URIProtocol {
	init(_ uri: String) throws
	init(_ uri: URI) throws
	init(scheme: URIScheme = "http", userinfo: URIUserinfo? = nil, host: URIHost, port: UInt? = nil, path: URIPath, query: URIQuery? = nil, fragment: URIFragment? = nil) throws
	var scheme: URIScheme { get }
	mutating func set(scheme: URIScheme) throws
	var opaque: String { get }
	var userinfo: URIUserinfo? { get set }
	var host: URIHost { get }
	mutating func set(host: URIHost) throws
	var port: UInt { get set }
	var path: URIPath { get set }
	var query: URIQuery? { get set }
	var fragment: URIFragment? { get set }
	func normalized() -> URI.HTTP
	var description: String
	init(stringLiteral: String)
	static func == (lhs: Self, rhs: Self) -> Bool
}
```

### Components of a URI

#### URIScheme

```swift
struct URIScheme : ExpressibleByStringLiteral, CustomStringConvertible, Equatable {
	let description: String
	let isNormalized: Bool
	init(_ scheme: String) throws
	func normalized() -> URIScheme
}
```

#### URIUserinfo

```swift
struct URIUserinfo : ExpressibleByStringLiteral, CustomStringConvertible, Equatable {
	let description: String
	let isNormalized: Bool
	init(_ userinfo: String) throws
	func normalized() -> URIUserinfo
}
```

#### URIHost

```swift
struct URIHost : ExpressibleByStringLiteral, CustomStringConvertible, Equatable {
	let description: String
	let isNormalized: Bool
	init(_ host: String) throws
	func normalized() -> URIHost
}
```

#### URIPath

```swift
struct URIPath : ExpressibleByStringLiteral, ExpressibleByArrayLiteral, CustomStringConvertible, Equatable {
	init(_ path: String) throws
	init(segments: [String], isRootless: Bool = false)
	var description: String { get }
	var segments: [String] { get set }
	var isRootless: Bool { get set }
	var isEmpty: Bool { get }
	func normalized() -> URIPath
}
```

#### URIQuery

```swift
struct URIQuery : ExpressibleByStringLiteral, ExpressibleByDictionaryLiteral, CustomStringConvertible, Equatable {
	init(_ query: String) throws
	init(params: URIQueryParams)
	var description: String { get }
	var params: URIQueryParams { get set }
	func normalized() -> URIQuery
}

struct URIQueryParams : Sequence, ExpressibleByDictionaryLiteral, CustomStringConvertible {
	typealias Element = (name: String, value: String)
	subscript(name: String) -> String? { get set }
	subscript(valuesFor name: String) -> [String] { get set }
	init(_ params: [(name: String, value: String)])
}
```

#### URIFragment

```swift
struct URIFragment : ExpressibleByStringLiteral, CustomStringConvertible, Equatable {
	var description: String { get }
	init(_ fragment: String) throws
	func normalized() -> URIFragment
}
```
