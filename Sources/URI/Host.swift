public struct URIHost : _URIComponent {
	public let description: String
	public let isNormalized: Bool

	init(_valid host: String, isNormalized: Bool) {
		description = host
		self.isNormalized = isNormalized
	}

	init(_ host: String) throws {
		try URIParser.validateHost(host)
		self.init(_valid: host, isNormalized: false)
	}

	public func normalized() -> URIHost {
		return self // TODO
	}
}

extension String {
	public init(_ host: URIHost) {
		self = host.description
	}
}

extension URIHost : ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(stringLiteral)
	}
}

extension URIHost : Equatable {
	public static func == (lhs: URIHost, rhs: URIHost) -> Bool {
		return lhs.normalized().description == rhs.normalized().description
	}
}
