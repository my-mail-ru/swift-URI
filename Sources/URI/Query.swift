public struct URIQuery : _URIComponent {
	private var storage: Storage

	public init(_valid query: String, isNormalized: Bool) {
		storage = Storage(query)
	}

	public init(_ query: String) throws {
		try URIParser.validateQuery(query)
		self.init(_valid: query, isNormalized: false)
	}

	public init(params: URIQueryParams) {
		storage = Storage(params: params)
	}

	public var description: String {
		return storage.query
	}

	public var params: URIQueryParams {
		get {
			return storage.params
		}
		set {
			if isKnownUniquelyReferenced(&storage) {
				storage._params = newValue
				storage._query = nil
			} else {
				storage = Storage(params: newValue)
			}
		}
	}

	public func normalized() -> URIQuery {
		return self // TODO
	}

	private final class Storage {
		var _query: String?
		var _params: URIQueryParams?

		init(_ query: String) {
			_query = query
			_params = nil
		}

		init(params: URIQueryParams) {
			_query = nil
			_params = params
		}

		var query: String {
			if let query = _query {
				return query
			}
			let query = _params!.description
			_query = query
			return query
		}

		var params: URIQueryParams {
			if let params = _params {
				return params
			}
			let params = URIQueryParams(_query![...]) // FIXME
			_params = params
			return params
		}
	}
}

extension String {
	public init(_ query: URIQuery) {
		self = query.description
	}
}

extension URIQuery : ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(stringLiteral)
	}
}

extension URIQuery : ExpressibleByDictionaryLiteral {
	public init(dictionaryLiteral: (String, String)...) {
		self.init(params: URIQueryParams(dictionaryLiteral))
	}
}

extension URIQuery : Equatable {
	public static func == (lhs: URIQuery, rhs: URIQuery) -> Bool {
		return lhs.normalized().storage.query == rhs.normalized().storage.query
	}
}
