enum URIWriter {
	// pct-encoded = "%" HEXDIG HEXDIG
	static func writePctEncoded(_ value: Character, to: inout String) {
		switch value {
			case "a"..."z": fallthrough
			case "A"..."Z": fallthrough
			case "0"..."9": fallthrough
			case "-": fallthrough
			case ".": fallthrough
			case "_": fallthrough
			case "~": to.append(value)
			default:
				for c in String(value).utf8 {
					to.append("%")
					for q in [c >> 4, c & 0xf] {
						let h = q < 10 ? q + 0x30 : q + 0x37
						to.append(Character(Unicode.Scalar(h)))
					}
				}
		}
	}

	static func writePctEncoded(_ value: String, to: inout String) {
		for c in value {
			writePctEncoded(c, to: &to)
		}
	}
}
