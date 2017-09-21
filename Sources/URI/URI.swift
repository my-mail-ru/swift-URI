// RFC3986

public struct URI : URIProtocol {
	var storage: URIStorage

	public init(_ uri: String) throws {
		storage = try URIStorage(uri)
	}

	public init(scheme: URIScheme, userinfo: URIUserinfo? = nil, host: URIHost? = nil, port: UInt? = nil, path: URIPath, query: URIQuery? = nil, fragment: URIFragment? = nil) throws {
		storage = try URIStorage(scheme: scheme, userinfo: userinfo, host: host, port: port, path: path, query: query, fragment: fragment)
	}

	public var scheme: URIScheme {
		get { return storage.scheme }
		set { prepareStorage(); storage.scheme = newValue }
	}

	public var opaque: String {
		return storage.opaque
	}

	public var authority: String? {
		return storage.authority
	}

	public var userinfo: URIUserinfo? {
		get { return storage.userinfo }
		set { prepareStorage(); storage.userinfo = newValue }
	}

	public var host: URIHost? {
		get { return storage.host }
		set { prepareStorage(); storage.host = newValue }
	}

	public var port: UInt? {
		get { return storage.port }
		set { prepareStorage(); storage.port = newValue }
	}
	
	public var path: URIPath {
		get { return storage.path }
		set { prepareStorage(); storage.path = newValue }
	}

	public var query: URIQuery? {
		get { return storage.query }
		set { prepareStorage(); storage.query = newValue }
	}

	public var fragment: URIFragment? {
		get { return storage.fragment }
		set { prepareStorage(); storage.fragment = newValue }
	}

	private mutating func prepareStorage() {
		if !isKnownUniquelyReferenced(&storage) {
			storage = URIStorage(storage)
		}
	}

	public func normalized() -> URI {
		return self // TODO
	}
}

extension URI : CustomStringConvertible {
	public var description: String {
		return storage.uri
	}
}
