public struct URIScheme : _URIComponent, CustomStringConvertible {
	public let description: String
	public let isNormalized: Bool

	public init(_valid scheme: String, isNormalized: Bool) {
		description = scheme
		self.isNormalized = isNormalized
	}

	public init(_ scheme: String) throws {
		let normalized = try URIParser.validateScheme(scheme)
		self.init(_valid: scheme, isNormalized: normalized)
	}

	public func normalized() -> URIScheme {
		return isNormalized ? self : URIScheme(_valid: description.lowercased(), isNormalized: true)
	}
}

extension URIScheme : ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(stringLiteral)
	}
}

extension URIScheme : Equatable {
	public static func == (lhs: URIScheme, rhs: URIScheme) -> Bool {
		return lhs.normalized().description == rhs.normalized().description
	}
}

extension String {
	public init(_ scheme: URIScheme) {
		self = scheme.description
	}
}

extension URIScheme {
	static let file: URIScheme = "file"
	static let ftp: URIScheme = "ftp"
	static let http: URIScheme = "http"
	static let https: URIScheme = "https"
	static let ws: URIScheme = "ws"
	static let wss: URIScheme = "wss"
}
