// RFC7230, section 2.7

extension URI {
	public struct HTTP : URIProtocol {
		var storage: URIStorage

		public init(_ uri: String) throws {
			storage = try URIStorage(uri)
			guard storage.scheme == "http" || storage.scheme == "https" else { throw URIError.invalidScheme }
			guard storage.host != nil && !storage.host!.isEmpty else { throw URIError.invalidAuthority }
		}

		public init(scheme: String = "http", userinfo: String? = nil, host: String, port: UInt? = nil, path: String, query: String? = nil, fragment: String? = nil) throws {
			guard scheme == "http" || scheme == "https" else { throw URIError.invalidScheme }
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

		public var host: String {
			return storage.host!
		}

		public var port: UInt {
			return storage.port ?? (storage.scheme == "https" ? 443 : 80)
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

		public mutating func set(scheme: String) throws {
			guard scheme == "http" || scheme == "https" else { throw URIError.invalidScheme }
			prepareStorage()
			try storage.set(scheme: scheme)
		}

		public mutating func set(userinfo: String?) throws {
			prepareStorage()
			try storage.set(userinfo: userinfo)
		}

		public mutating func set(host: String) throws {
			prepareStorage()
			guard !host.isEmpty else { throw URIError.invalidAuthority }
			try storage.set(host: host)
		}

		public mutating func set(port: UInt) throws {
			prepareStorage()
			let portOpt: UInt?
			switch (storage.scheme, port) {
				case ("http", 80): portOpt = nil
				case ("https", 443): portOpt = nil
				default: portOpt = port
			}
			try storage.set(port: portOpt)
		}

		public mutating func set(path: String) throws {
			prepareStorage()
			try storage.set(path: path)
		}

		public mutating func set(query: String?) throws {
			prepareStorage()
			try storage.set(query: query)
		}

		public mutating func set(fragment: String?) throws {
			prepareStorage()
			try storage.set(fragment: fragment)
		}

		private mutating func prepareStorage() {
			if !isKnownUniquelyReferenced(&storage) {
				storage = URIStorage(storage)
			}
		}

		public var normalized: URI.HTTP {
			// TODO
			return self
		}
	}
}

extension URI.HTTP : CustomStringConvertible {
	public var description: String {
		return storage.uri
	}
}
