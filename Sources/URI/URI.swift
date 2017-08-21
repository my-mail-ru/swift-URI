// RFC3986
public struct URI : URIProtocol {
	var storage: URIStorage

	public init(_ uri: String) throws {
		storage = try URIStorage(uri)
	}

	public init(scheme: String, userinfo: String? = nil, host: String? = nil, port: UInt? = nil, path: String, query: String? = nil, fragment: String? = nil) throws {
		storage = try URIStorage(scheme: scheme, userinfo: userinfo, host: host, port: port, path: path, query: query, fragment: fragment)
	}

	public var scheme: String {
		return storage.scheme
	}

	public var opaque: String {
		return storage.opaque
	}

	public var userinfo: String? {
		return storage.userinfo
	}

	public var host: String? {
		return storage.host
	}

	public var port: UInt? {
		return storage.port
	}
	
	public var path: String {
		return storage.path
	}

	public var query: String? {
		return storage.query
	}

	public var fragment: String? {
		return storage.fragment
	}

	var pathSegments: PathSegments {
		get { return storage.pathSegments }
		set { storage.pathSegments = newValue }
	}

	var queryParams: QueryParams {
		return storage.queryParams
	}

	mutating func set(scheme: String) throws {
		prepareStorage()
		try storage.set(scheme: scheme)
	}

	mutating func set(userinfo: String?) throws {
		prepareStorage()
		try storage.set(userinfo: userinfo)
	}

	mutating func set(host: String?) throws {
		prepareStorage()
		try storage.set(host: host)
	}

	mutating func set(port: UInt?) throws {
		prepareStorage()
		try storage.set(port: port)
	}

	mutating func set(path: String) throws {
		prepareStorage()
		try storage.set(path: path)
	}

	mutating func set(query: String?) throws {
		prepareStorage()
		try storage.set(query: query)
	}

	mutating func set(fragment: String?) throws {
		prepareStorage()
		try storage.set(fragment: fragment)
	}

	private mutating func prepareStorage() {
		if !isKnownUniquelyReferenced(&storage) {
			storage = URIStorage(storage)
		}
	}

	public var normalized: URI {
		// TODO
		return self
	}
}

extension URI : CustomStringConvertible {
	public var description: String {
		return storage.uri
	}
}
