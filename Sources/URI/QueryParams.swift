struct QueryParams {
	var original: [(name: String, value: String)]?
	var storage: [String: [String]] {
		didSet { original = nil }
	}

	subscript(name: String) -> String? {
		get { return storage[name].flatMap { $0.first } }
		set { storage[name] = newValue.map { [$0] } }
	}

	subscript(valuesFor name: String) -> [String] {
		get { return storage[name] ?? [] }
		set { storage[name] = newValue.isEmpty ? nil : newValue }
	}

	init(_ params: [(name: String, value: String)]) {
		original = params
		var dict = [String: [String]]()
		for p in params {
			dict[p.name, default: []].append(p.value)
		}
		storage = dict
	}

	init(_ query: Substring) {
		var params = [(name: String, value: String)]()
		var key = ""
		var current = ""
		var i = query.startIndex
		loop: while i != query.endIndex {
			let c = query[i]
			switch c {
				case "=":
					key = current
					current = ""
				case "&":
					params.append((key, current))
					key = ""
					current = ""
				case "%":
					current += URIParser.decodePctEncoded(uri: query, index: &i)
					continue loop
				case "+":
					current.append(" ")
				default: 
					current.append(c)
			}
			query.formIndex(after: &i)
		}
		if !key.isEmpty {
			params.append((key, current))
		}
		self.init(params)
	}
}

extension QueryParams : ExpressibleByDictionaryLiteral {
	init(dictionaryLiteral: (String, String)...) {
		self.init(dictionaryLiteral)
	}
}

extension QueryParams : Sequence {
	public func makeIterator() -> AnyIterator<(name: String, value: String)> {
		if let original = original {
			return AnyIterator(original.makeIterator())
		} else {
			return AnyIterator(StorageIterator(storage.makeIterator()))
		}
	}

	struct StorageIterator : IteratorProtocol {
		var params: DictionaryIterator<String, [String]>
		var param: (name: String, values: IndexingIterator<[String]>)?

		init(_ iterator: DictionaryIterator<String, [String]>) {
			params = iterator
			param = params.next().map { (name: $0.key, values: $0.value.makeIterator()) }
		}

		mutating func next() -> (name: String, value: String)? {
			while param != nil {
				if let value = param!.values.next() {
					return (name: param!.name, value: value)
				} else {
					param = params.next().map { (name: $0.key, values: $0.value.makeIterator()) }
				}
			}
			return nil
		}
	}
}

extension QueryParams : CustomStringConvertible {
	var description: String {
		var query: String = ""
		let i = makeIterator()
		if let (name, value) = i.next() {
			QueryParams.writePctEncoded(name, to: &query)
			query.append("=")
			QueryParams.writePctEncoded(value, to: &query)
		} else {
			return query
		}
		while let (name, value) = i.next() {
			query.append("&")
			QueryParams.writePctEncoded(name, to: &query)
			query.append("=")
			QueryParams.writePctEncoded(value, to: &query)
		}
		return query
	}

	static private func writePctEncoded(_ value: String, to: inout String) {
		for c in value {
			switch c {
				case " ": to.append("+")
				default: URIWriter.writePctEncoded(c, to: &to)
			}
		}
	}
}
