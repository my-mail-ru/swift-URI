// RFC7230, section 2.7

extension URI {
	public struct HTTP : URIProtocol {
		var storage: URIStorage

		public init(_ uri: String) throws {
			storage = try URIStorage(uri)
			guard storage.scheme == "http" || storage.scheme == "https" else { throw URIError.invalidScheme }
			guard storage.host != nil && storage.host != "" else { throw URIError.invalidAuthority }
		}

		public init(_ uri: URI) throws {
			storage = uri.storage
			guard storage.scheme == "http" || storage.scheme == "https" else { throw URIError.invalidScheme }
			guard storage.host != nil && storage.host != "" else { throw URIError.invalidAuthority }
		}

		public init(scheme: URIScheme = "http", userinfo: URIUserinfo? = nil, host: URIHost, port: UInt? = nil, path: URIPath, query: URIQuery? = nil, fragment: URIFragment? = nil) throws {
			guard scheme == "http" || scheme == "https" else { throw URIError.invalidScheme }
			guard host != "" else { throw URIError.invalidAuthority }
			storage = try URIStorage(scheme: scheme, userinfo: userinfo, host: host, port: port, path: path, query: query, fragment: fragment)
		}

		public var scheme: URIScheme {
			return storage.scheme
		}

		public mutating func set(scheme: URIScheme) throws {
			guard scheme == "http" || scheme == "https" else { throw URIError.invalidScheme }
			prepareStorage()
			storage.scheme = scheme
			switch (scheme, storage.port) {
				case (.http, .some(80)): storage.port = nil
				case (.https, .some(443)): storage.port = nil
				case (.http, nil): storage.port = 443
				case (.https, nil): storage.port = 80
				default: break
			}
		}

		public var opaque: String {
			return storage.opaque
		}

		public var userinfo: URIUserinfo? {
			get { return storage.userinfo }
			set { prepareStorage(); storage.userinfo = newValue }
		}

		public var host: URIHost {
			return storage.host!
		}

		public mutating func set(host: URIHost) throws {
			guard host != "" else { throw URIError.invalidAuthority }
			prepareStorage()
			storage.host = host
		}

		public var port: UInt {
			get { return storage.port ?? (storage.scheme == "https" ? 443 : 80) }
			set {
				prepareStorage();
				let port: UInt?
				switch (scheme, newValue) {
					case (.http, 80): port = nil
					case (.https, 443): port = nil
					default: port = newValue
				}
				storage.port = port
			}
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

		public func normalized() -> URI.HTTP {
			return self // TODO
		}
	}
}

extension URI.HTTP : CustomStringConvertible {
	public var description: String {
		return storage.uri
	}
}

extension URI {
	init(_ uri: URI.HTTP) {
		storage = uri.storage
	}
}
