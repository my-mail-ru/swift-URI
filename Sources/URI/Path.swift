public struct URIPath : _URIComponent {
	private var storage: Storage

	public init(_valid path: String, isNormalized: Bool) {
		storage = Storage(path)
	}

	public init(_ path: String) throws {
		try URIParser.validatePath(path)
		self.init(_valid: path, isNormalized: false)
	}

	public init(segments: [String], isRootless: Bool = false) {
		storage = Storage(segments: segments, rootless: isRootless)
	}

	public var description: String {
		return storage.path
	}

	public var segments: [String] {
		get {
			return storage.segments
		}
		set {
			if isKnownUniquelyReferenced(&storage) {
				storage._segments = newValue
				storage._path = nil
			} else {
				storage = Storage(segments: newValue, rootless: storage.rootless)
			}
		}
	}

	public var isRootless: Bool {
		get {
			return storage.rootless
		}
		set {
			if isKnownUniquelyReferenced(&storage) {
				storage._rootless = newValue
				storage._path = nil
			} else {
				storage = Storage(segments: storage.segments, rootless: newValue)
			}
		}
	}

	public var isEmpty: Bool {
		return storage.isEmpty
	}

	public func normalized() -> URIPath {
		return self // TODO
	}

	private final class Storage {
		var _path: String? = nil
		var _segments: [String]? = nil
		var _rootless: Bool? = nil

		init(_ path: String) {
			_path = path
		}

		init(segments: [String], rootless: Bool) {
			_segments = segments
			_rootless = rootless
		}

		var path: String {
			if let path = _path {
				return path
			}
			let path = format()
			_path = path
			return path
		}

		var segments: [String] {
			if let segments = _segments {
				return segments
			}
			let p = parse()
			_segments = p.segments
			_rootless = p.rootless
			return p.segments
		}

		var rootless: Bool {
			if let rootless = _rootless {
				return rootless
			}
			let p = parse()
			_segments = p.segments
			_rootless = p.rootless
			return p.rootless
		}

		var isEmpty: Bool {
			if let path = _path {
				return path.isEmpty
			}
			return _segments!.isEmpty
		}

		func parse() -> (segments: [String], rootless: Bool) {
			var segments = [String]()
			let rootless: Bool
			let path = self._path![...] // FIXME
			var i = path.startIndex
			if i != path.endIndex {
				rootless = path[i] != "/"
				if !rootless {
					path.formIndex(after: &i)
				}
				var segment = ""
				loop: while i != path.endIndex {
					let c = path[i]
					switch c {
						case "/":
							segments.append(segment)
							segment = ""
						case "%":
							segment += URIParser.decodePctEncoded(uri: path, index: &i)
							continue loop
						default:
							segment.append(c)
					}
					path.formIndex(after: &i)
				}
				segments.append(segment)
			} else {
				rootless = false
			}
			return (segments: segments, rootless: rootless)
		}

		func format() -> String {
			var path = "";
			let rootless = _rootless!
			var i = _segments!.makeIterator()
			if let segment = i.next() {
				if !rootless {
					path.append("/")
				}
				URIWriter.writePctEncoded(segment, to: &path)
			}
			while let segment = i.next() {
				path.append("/")
				URIWriter.writePctEncoded(segment, to: &path)
			}
			return path
		}
	}
}

extension String {
	public init(_ path: URIPath) {
		self = path.description
	}
}

extension URIPath : ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(stringLiteral)
	}
}

extension URIPath : ExpressibleByArrayLiteral {
	public init(arrayLiteral: String...) {
		self.init(segments: arrayLiteral)
	}
}

extension URIPath : Equatable {
	public static func == (lhs: URIPath, rhs: URIPath) -> Bool {
		return lhs.normalized().storage.path == rhs.normalized().storage.path
	}
}
