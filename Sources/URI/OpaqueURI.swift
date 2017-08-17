public protocol OpaqueURI : CustomStringConvertible {
	/// `scheme` component of the URI.
	var scheme: String { get }

	/// `authority`, `path`, `query` and `fragment` components of the URI.
	var opaque: String { get }

	/// `path` component of the URI.
	var path: String { get }

	/// Initalize an URI from a string.
	init(_ uri: String) throws
}

public protocol URIProtocol : OpaqueURI, Equatable {
	/// Normalized representation of the URI.
	var normalized: Self { get }
}

extension URIProtocol {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.normalized.description == rhs.normalized.description
	}
}

extension String {
	public init<T : OpaqueURI>(_ uri: T) {
		self = uri.description
	}
}
