public protocol OpaqueURI : CustomStringConvertible, ExpressibleByStringLiteral {
	/// `scheme` component of the URI.
	var scheme: URIScheme { get }

	/// `authority`, `path`, `query` and `fragment` components of the URI.
	var opaque: String { get }

	/// `path` component of the URI.
	var path: URIPath { get }

	/// Initalize a URI from a string.
	init(_ uri: String) throws
}

extension OpaqueURI {
	public init(stringLiteral: String) {
		try! self.init(stringLiteral)
	}
}

public protocol URIProtocol : OpaqueURI, Equatable {
	/// Normalized representation of the URI.
	func normalized() -> Self
}

extension URIProtocol {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.normalized().description == rhs.normalized().description
	}
}

extension String {
	public init<T : OpaqueURI>(_ uri: T) {
		self = uri.description
	}
}
