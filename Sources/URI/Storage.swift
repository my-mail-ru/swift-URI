final class URIStorage {
	private var _uri: String?
	private var _scheme: URIComponentStorage<URIScheme>
	private var _opaque: URICompositeStorage?
	private var _authority: (
		authority: URICompositeStorage?,
		userinfo: URIComponentStorage<URIUserinfo>?,
		host: URIComponentStorage<URIHost>,
		port: UInt?
	)?
	private var _path: URIComponentStorage<URIPath>
	private var _query: URIComponentStorage<URIQuery>?
	private var _fragment: URIComponentStorage<URIFragment>?

	// URI         = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
	//
	// hier-part   = "//" authority path-abempty
	//             / path-absolute
	//             / path-rootless
	//             / path-empty
	init(_ uri: String) throws {
		var i = uri.startIndex
		let ps = try URIParser.parseScheme(uri: uri, index: &i)
		_scheme = .inplace(ps.value, isNormalized: ps.isNormalized)
		guard i != uri.endIndex else { throw URIError.invalidScheme }
		uri.formIndex(after: &i)
		_opaque = .inplace(uri[i..<uri.endIndex])
		_authority = try URIParser.parseAuthority(uri: uri, index: &i)
		_path = .inplace(try URIParser.parsePath(uri: uri, index: &i), isNormalized: false)
		if i != uri.endIndex && uri[i] == "?" {
			uri.formIndex(after: &i)
			_query = .inplace(try URIParser.parseQuery(uri: uri, index: &i), isNormalized: false)
		} else {
			_query = nil
		}
		if i != uri.endIndex && uri[i] == "#" {
			uri.formIndex(after: &i)
			_fragment = .inplace(try URIParser.parseFragment(uri: uri, index: &i), isNormalized: false)
		} else {
			_fragment = nil
		}
		_uri = uri
	}

	init(scheme: URIScheme, userinfo: URIUserinfo?, host: URIHost?, port: UInt?, path: URIPath, query: URIQuery?, fragment: URIFragment?) throws {
		_scheme = .outside(scheme)
		if let host = host {
			_authority = (authority: nil, userinfo: userinfo.map { .outside($0) }, host: .outside(host), port: port)
		} else {
			guard userinfo == nil && port == nil else { throw URIError.invalidAuthority }
		}
		_path = .outside(path)
		_query = query.map { .outside($0) }
		_fragment = fragment.map { .outside($0) }
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

		var uri = "\(_scheme.substring):"
		if let opaque = _opaque {
			uri += opaque.substring
		} else {
			writeOpaque(to: &uri)
		}
		return uri
	}

	var scheme: URIScheme {
		get { return _scheme.value }
		set {
			_scheme = .outside(newValue)
			_uri = nil
		}
	}

	var opaque: String {
		if let opaque = _opaque {
			return opaque.string
		}
		var opaque = ""
		writeOpaque(to: &opaque)
		_opaque = .outside(opaque)
		return opaque
	}

	var authority: String? {
		guard let auth = _authority else { return nil }
		if let authority = auth.authority {
			return authority.string
		}
		var authority = ""
		writeAuthority(to: &authority)
		_authority!.authority = .outside(authority)
		return authority
	}

	var userinfo: URIUserinfo? {
		get { return _authority?.userinfo?.value }
		set {
			if let userinfo = newValue {
				_authority = (authority: nil, userinfo: .outside(userinfo), host: _authority?.host ?? .outside(""), port: _authority?.port)
			} else {
				_authority?.userinfo = nil
				_authority?.authority = nil
			}
			_opaque = nil
			_uri = nil
		}
	}

	var host: URIHost? {
		get { return _authority?.host.value }
		set {
			if let host = newValue {
				_authority = (authority: nil, userinfo: _authority?.userinfo, host: .outside(host), port: _authority?.port)
			} else {
				_authority = nil
			}
			_opaque = nil
			_uri = nil
		}
	}

	var port: UInt? {
		get { return _authority?.port }
		set {
			if let port = newValue {
				_authority = (authority: nil, userinfo: _authority?.userinfo, host: _authority?.host ?? .outside(""), port: port)
			} else {
				_authority?.port = nil
				_authority?.authority = nil
			}
			_opaque = nil
			_uri = nil
		}
	}
	
	var path: URIPath {
		get { return _path.value }
		set {
			_path = .outside(newValue)
			_opaque = nil
			_uri = nil
		}
	}

	var query: URIQuery? {
		get { return _query?.value }
		set {
			_query = newValue.map { .outside($0) }
			_opaque = nil
			_uri = nil
		}
	}

	var fragment: URIFragment? {
		get { return _fragment?.value }
		set {
			_fragment = newValue.map { .outside($0) }
			_opaque = nil
			_uri = nil
		}
	}

	func writeOpaque(to uri: inout String) {
		if let auth = _authority {
			uri += "//"
			if let authority = auth.authority {
				uri += authority.substring
			} else {
				writeAuthority(to: &uri)
			}
		}
		uri += _path.substring
		if let query = _query {
			uri += "?" + query.substring
		}
		if let fragment = _fragment {
			uri += "#" + fragment.substring
		}
	}

	func writeAuthority(to uri: inout String) {
		let auth = _authority!
		if let userinfo = auth.userinfo {
			uri += userinfo.substring + "@"
		}
		uri += auth.host.substring
		if let port = auth.port {
			uri += ":\(port)"
		}
	}
}
