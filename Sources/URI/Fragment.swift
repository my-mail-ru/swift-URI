public struct URIFragment : _URIComponent {
	public var description: String

	init(_valid fragment: String, isNormalized: Bool) {
		description = fragment
	}

	init(_ fragment: String) throws {
		try URIParser.validateFragment(fragment)
		self.init(_valid: fragment, isNormalized: false)
	}
/* TODO
	init(decoded: String) {
	}

	var decoded: String {
		get {
		}
		set {
		}
	}
*/
	func normalized() -> URIFragment {
		return self // TODO
	}
}

extension String {
	public init(_ fragment: URIFragment) {
		self = fragment.description
	}
}

extension URIFragment : ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(stringLiteral)
	}
}

extension URIFragment : Equatable {
	public static func == (lhs: URIFragment, rhs: URIFragment) -> Bool {
		return lhs.normalized().description == rhs.normalized().description
	}
}
