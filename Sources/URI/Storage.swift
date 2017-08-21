final class URIStorage {
	private var _uri: String?
	private var _scheme: Substring
	private var _opaque: Substring?
	private var _authority: (
		authority: Substring?,
		userinfo: Substring?,
		host: Substring,
		port: Substring?
	)?
	private var _path: Substring
	private var _query: Substring?
	private var _fragment: Substring?

	private var _pathSegments: PathSegments? = nil
	private var _queryParams: QueryParams? = nil

	// URI         = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
	//
	// hier-part   = "//" authority path-abempty
	//             / path-absolute
	//             / path-rootless
	//             / path-empty
	init(_ uri: String) throws {
		var i = uri.startIndex
		_scheme = try URIParser.parseScheme(uri: uri, index: &i)
		guard i != uri.endIndex else { throw URIError.invalidScheme }
		uri.formIndex(after: &i)
		_opaque = uri[i..<uri.endIndex]
		_authority = try URIParser.parseAuthority(uri: uri, index: &i)
		_path = try URIParser.parsePath(uri: uri, index: &i)
		if i != uri.endIndex && uri[i] == "?" {
			uri.formIndex(after: &i)
			_query = try URIParser.parseQuery(uri: uri, index: &i)
		} else {
			_query = nil
		}
		if i != uri.endIndex && uri[i] == "#" {
			uri.formIndex(after: &i)
			_fragment = try URIParser.parseFragment(uri: uri, index: &i)
		} else {
			_fragment = nil
		}
		_uri = uri
	}

	init(scheme: String, userinfo: String?, host: String?, port: UInt?, path: String, query: String?, fragment: String?) throws {
		try URIParser.validateScheme(scheme)
		_scheme = Substring(scheme)
		if let host = host {
			try URIParser.validateHost(host)
			let ui: Substring?
			if let userinfo = userinfo {
				try URIParser.validateUserinfo(userinfo);
				ui = Substring(userinfo)
			} else {
				ui = nil
			}
			let pt = port.map { Substring(String($0)) }
			_authority = (authority: nil, userinfo: ui, host: Substring(host), port: pt)
		} else {
			guard userinfo == nil && port == nil else { throw URIError.invalidAuthority }
		}
		try URIParser.validatePath(path)
		_path = Substring(path)
		_query = try query.map { try URIParser.validateQuery($0); return Substring($0) }
		_fragment = try fragment.map { try URIParser.validateFragment($0); return Substring($0) }
	}

	init(_ uri: URIStorage) {
		_uri = uri._uri
		_scheme = uri._scheme
		_opaque = uri._opaque
		_authority = uri._authority
		_path = uri._path
		_query = uri._query
		_fragment = uri._fragment
	}

	var uri: String {
		if let uri = _uri {
			return uri
		}

		var uri: String = _scheme + ":"
		if let opaque = _opaque {
			uri += opaque
		} else {
			if let auth = _authority {
				uri += "//"
				if let authority = auth.authority {
					uri += authority
				} else {
					if let userinfo = auth.userinfo {
						uri += userinfo + "@"
					}
					uri += auth.host
					if let port = auth.port {
						uri += ":" + port
					}
				}
			}
			uri += _path
			if let query = _query {
				uri += "?" + query
			}
			if let fragment = _fragment {
				uri += "#" + fragment
			}
		}

		_uri = uri
		var next = uri.index(uri.startIndex, offsetBy: _scheme.count)
		_scheme = uri[uri.startIndex..<next]
		uri.formIndex(after: &next)
		_opaque = uri[next..<uri.endIndex]
		if let auth = _authority {
			next = uri.index(next, offsetBy: 2)
			let start = next
			if let ui = auth.userinfo {
				let end = uri.index(next, offsetBy: ui.count)
				_authority!.userinfo = uri[next..<end]
				next = uri.index(after: end)
			}
			let end = uri.index(next, offsetBy: auth.host.count)
			_authority!.host = uri[next..<end]
			if let p = auth.port {
				next = uri.index(after: end)
				let end = uri.index(next, offsetBy: p.count)
				_authority!.port = uri[next..<end]
				next = end
			}
			_authority!.authority = uri[start..<end]
		}
		let end = uri.index(next, offsetBy: _path.count)
		_path = uri[next..<end]
		next = end
		if let query = _query {
			next = uri.index(after: next)
			let end = uri.index(next, offsetBy: query.count)
			_query = uri[next..<end]
			next = end
		}
		if let fragment = _fragment {
			next = uri.index(after: next)
			let end = uri.index(next, offsetBy: fragment.count)
			_fragment = uri[next..<end]
		}
		return uri
	}

	var scheme: String {
		return String(_scheme)
	}

	var opaque: String {
		if _opaque == nil { _ = uri }
		return String(_opaque!)
	}

	var userinfo: String? {
		return _authority?.userinfo.map(String.init)
	}

	var host: String? {
		return _authority.map { String($0.host) }
	}

	var port: UInt? {
		return _authority?.port.flatMap { UInt(String($0)) }
	}
	
	var path: String {
		return String(_path)
	}

	var query: String? {
		return _query.map(String.init)
	}

	var fragment: String? {
		return _fragment.map(String.init)
	}

	var pathSegments: PathSegments {
		get {
			if let segments = _pathSegments {
				return segments
			}
			let segments = PathSegments(_path)
			_pathSegments = segments
			return segments
		}
		set {
			_pathSegments = newValue
			_path = Substring("\(newValue)")
			_opaque = nil
			_uri = nil
		}
	}

	var queryParams: QueryParams {
		if let params = _queryParams {
			return params
		}
		let params = _query.map(QueryParams.init) ?? [:]
		_queryParams = params
		return params
	}

	func set(scheme: String) throws {
		var i = scheme.startIndex
		_scheme = try URIParser.parseScheme(uri: scheme, index: &i)
		guard i == scheme.endIndex else { throw URIError.invalidScheme }
		_uri = nil
	}

	func set(userinfo: String?) throws {
		if let userinfo = userinfo {
			try URIParser.validateUserinfo(userinfo)
			let ui = Substring(userinfo)
			if _authority != nil {
				_authority!.userinfo = ui
			} else {
				_authority = (authority: nil, userinfo: ui, host: Substring(), port: nil)
			}
		} else {
			_authority?.userinfo = nil
		}
		_authority?.authority = nil
		_opaque = nil
		_uri = nil
	}

	func set(host: String?) throws {
		if let host = host {
			try URIParser.validateHost(host)
			if _authority != nil {
				_authority!.host = Substring(host)
				_authority!.authority = nil
			} else {
				_authority = (authority: nil, userinfo: nil, host: Substring(host), port: nil)
			}
		} else {
			_authority = nil
		}
		_opaque = nil
		_uri = nil
	}

	func set(port: UInt?) throws {
		if let port = port {
			let port = Substring(String(port))
			if _authority != nil {
				_authority!.port = port
				_authority!.authority = nil
			} else {
				_authority = (authority: nil, userinfo: nil, host: Substring(), port: port)
			}
		} else {
			_authority?.port = nil
			_authority?.authority = nil
		}
		_opaque = nil
		_uri = nil
	}

	func set(path: String) throws {
		try URIParser.validatePath(path)
		_path = Substring(path)
		_opaque = nil
		_uri = nil
	}

	func set(query: String?) throws {
		if let query = query {
			try URIParser.validateQuery(query)
			_query = Substring(query)
		} else {
			_query = nil
		}
		_opaque = nil
		_uri = nil
	}

	func set(fragment: String?) throws {
		if let fragment = fragment {
			try URIParser.validateFragment(fragment)
			_fragment = Substring(fragment)
		} else {
			_fragment = nil
		}
		_opaque = nil
		_uri = nil
	}
}
