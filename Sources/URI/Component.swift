protocol _URIComponent : CustomStringConvertible {
	init(_valid: String, isNormalized: Bool)
}

enum URIComponentStorage<T : _URIComponent> {
	case inplace(Substring, isNormalized: Bool)
	case outside(T)

	var value: T {
		mutating get {
			switch self {
				case .inplace(let substring, let isNormalized):
					let value = T.init(_valid: String(substring), isNormalized: isNormalized)
					self = .outside(value)
					return value
				case .outside(let value):
					return value
			}
		}
	}

	var substring: Substring {
		switch self {
			case .inplace(let substring, _):
				return substring
			case .outside(let value):
				return Substring(value.description)
		}
	}
}

enum URICompositeStorage {
	case inplace(Substring)
	case outside(String)

	var substring: Substring {
		switch self {
			case .inplace(let s): return s
			case .outside(let s): return s[...]
		}
	}

	var string: String {
		switch self {
			case .inplace(let s): return String(s)
			case .outside(let s): return s
		}
	}
}
