public struct URIUserinfo : _URIComponent {
	public let description: String
	public let isNormalized: Bool

	init(_valid userinfo: String, isNormalized: Bool) {
		description = userinfo
		self.isNormalized = isNormalized
	}

	public init(_ userinfo: String) throws {
		try URIParser.validateUserinfo(userinfo)
		self.init(_valid: userinfo, isNormalized: false)
	}

	public func normalized() -> URIUserinfo {
		return self // TODO
	}
}

extension String {
	public init(_ userinfo: URIUserinfo) {
		self = userinfo.description
	}
}

extension URIUserinfo : ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(stringLiteral)
	}
}

extension URIUserinfo : Equatable {
	public static func == (lhs: URIUserinfo, rhs: URIUserinfo) -> Bool {
		return lhs.normalized().description == rhs.normalized().description
	}
}
