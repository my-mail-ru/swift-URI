struct QueryParams : ExpressibleByDictionaryLiteral {
	let original: [(name: String, value: String)]

	init(dictionaryLiteral: (String, String)...) {
		original = dictionaryLiteral
	}

	init(_ query: Substring) {
		var params = [(name: String, value: String)]()
		var key = ""
		var value = ""
		var isValue = false
		var hasPairs = false
		var i = query.startIndex
		while i != query.endIndex {
			let c = query[i]
			switch c {
				case "=":
					hasPairs = true
					isValue = true
				case "&":
					params.append((key, value))
					isValue = false
				case "%": break // FIXME
				case "+":
					value.append(" ")
				default: 
					if isValue {
						value.append(c)
					} else {
						key.append(c)
					}
			}
			query.formIndex(after: &i)
		}
		if hasPairs {
			params.append((key, value))
		}
		self.original = params
	}
}
