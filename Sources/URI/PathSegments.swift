struct PathSegments {
	var storage: [String]
	var rootless: Bool

	init(_ segments: [String], rootless: Bool = false) {
		storage = segments
		self.rootless = rootless
	}

	init(_ path: Substring) {
		var segments = [String]()
		let rootless: Bool
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
		self.init(segments, rootless: rootless)
	}
}

extension PathSegments : ExpressibleByArrayLiteral {
	public init(arrayLiteral: String...) {
		self.init(arrayLiteral)
	}
}

extension PathSegments : Sequence {
	func makeIterator() -> Array<String>.Iterator {
		return storage.makeIterator()
	}
}

extension PathSegments : RandomAccessCollection, RangeReplaceableCollection {
	init() {
		self.init([])
	}

	mutating func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, C.Element == Element {
		storage.replaceSubrange(subrange, with: newElements)
	}

	var startIndex: Int {
		return storage.startIndex
	}

	var endIndex: Int {
		return storage.endIndex
	}

	func index(after i: Int) -> Int {
		return storage.index(after: i)
	}

	subscript(index: Int) -> String {
		get { return storage[index] }
		set { storage[index] = newValue }
	}
}

extension PathSegments : CustomStringConvertible {
	var description: String {
		var path = "";
		var i = makeIterator()
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
