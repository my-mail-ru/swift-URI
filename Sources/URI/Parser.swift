enum URIParser {
	// scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
	static func parseScheme(uri: String, index i: inout String.Index) throws -> (value: Substring, isNormalized: Bool) {
		guard i != uri.endIndex else { throw URIError.invalidScheme }
		// [RFC3986, section 3.1] ... should only produce lowercase scheme names for consistency.
		var isNormalized = true
		let start = i
		switch uri[i] {
			case "a"..."z": break
			case "A"..."Z": isNormalized = false
			default: throw URIError.invalidScheme
		}
		uri.formIndex(after: &i)
		loop: while i != uri.endIndex {
			switch uri[i] {
				case "a"..."z": break
				case ":": break loop
				case "0"..."9": break
				case "A"..."Z": isNormalized = false
				case "+": break
				case "-": break
				case ".": break
				default: throw URIError.invalidScheme
			}
			uri.formIndex(after: &i)
		}
		return (value: uri[start..<i], isNormalized: isNormalized)
	}

	// authority   = [ userinfo "@" ] host [ ":" port ]
	//
	// userinfo    = *( unreserved / pct-encoded / sub-delims / ":" )
	//
	// host        = IP-literal / IPv4address / reg-name
	//
	// IP-literal  = "[" ( IPv6address / IPvFuture  ) "]"
	//
	// IPvFuture   = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
	//
	// IPv6address =                            6( h16 ":" ) ls32
	//             /                       "::" 5( h16 ":" ) ls32
	//             / [               h16 ] "::" 4( h16 ":" ) ls32
	//             / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
	//             / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
	//             / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
	//             / [ *4( h16 ":" ) h16 ] "::"              ls32
	//             / [ *5( h16 ":" ) h16 ] "::"              h16
	//             / [ *6( h16 ":" ) h16 ] "::"
	//
	// ls32        = ( h16 ":" h16 ) / IPv4address
	//             ; least-significant 32 bits of address
	//
	// h16         = 1*4HEXDIG
	//             ; 16 bits of address represented in hexadecimal
	//
	// IPv4address = dec-octet "." dec-octet "." dec-octet "." dec-octet
	//
	// dec-octet   = DIGIT                 ; 0-9
	//             / %x31-39 DIGIT         ; 10-99
	//             / "1" 2DIGIT            ; 100-199
	//             / "2" %x30-34 DIGIT     ; 200-249
	//             / "25" %x30-35          ; 250-255
	//
	// reg-name    = *( unreserved / pct-encoded / sub-delims )
	//
	// port        = *DIGIT
	static func parseAuthority(uri: String, index i: inout String.Index) throws -> (authority: URICompositeStorage?, userinfo: URIComponentStorage<URIUserinfo>?, host: URIComponentStorage<URIHost>, port: UInt?)? {
		guard i != uri.endIndex && uri[i] == "/" else { return nil }
		let ni = uri.index(after: i)
		guard ni != uri.endIndex && uri[ni] == "/" else { return nil }
		i = uri.index(after: ni)

		enum State {
			case userinfoOrHost
			case userinfoOrPort
			case userinfo
			case host
			case hostIPv6
			case hostIPv6Done
			case port
		}
		var state = State.userinfoOrHost

		let start = i
		var at: String.Index?
		var colon: String.Index?

		var isNormalized = true
		var userinfoIsNormalized = true
		var hostIsNormalized = true

		loop: while i != uri.endIndex {
			switch uri[i] {
				case let v where unreserved(v): break
				case "/":
					break loop
				case "%": try skipPctEncoded(uri: uri, index: &i, isNormalized: &isNormalized)
				case ":":
					switch state {
						case .userinfoOrHost:
							state = .userinfoOrPort
							colon = i
							uri.formIndex(after: &i)
							portLoop: while i != uri.endIndex {
								switch uri[i] {
									case "/": break loop
									case "0"..."9": break
									default:
										state = .userinfo
										colon = nil
										break portLoop
								}
								uri.formIndex(after: &i)
							}
							if state != .userinfo {
								break loop
							}
						case .host:
							state = .port
							colon = i
							uri.formIndex(after: &i)
							while i != uri.endIndex {
								switch uri[i] {
									case "/": break loop
									case "0"..."9": break
									default: throw URIError.invalidAuthority
								}
								uri.formIndex(after: &i)
							}
							break loop
						case .userinfo: break
						case .hostIPv6: break
						default:
							throw URIError.invalidAuthority
					}
				case "@":
					switch state {
						case .userinfoOrPort:
							colon = nil
							fallthrough
						case .userinfoOrHost, .userinfo:
							at = i
							state = .host
							userinfoIsNormalized = isNormalized
							isNormalized = true
						default:
							throw URIError.invalidAuthority
					}
				case "[":
					switch state {
						case .userinfoOrHost where i == start,
							.host where i == (at.map { uri.index(after: $0) } ?? start):
							state = .hostIPv6
						default:
							throw URIError.invalidAuthority
					}
				case "]":
					switch state {
						case .hostIPv6:
							state = .hostIPv6Done
						default:
							throw URIError.invalidAuthority
					}
				case let v where subDelims(v): break
				default: throw URIError.invalidAuthority
			}
			uri.formIndex(after: &i)
		}
		let end = i
		switch state {
			case .hostIPv6:
				throw URIError.invalidAuthority
			case .hostIPv6Done where uri[uri.index(before: end)] != "]":
				throw URIError.invalidAuthority
			default:
				hostIsNormalized = isNormalized
		}
		return (
			authority: .inplace(uri[start..<end]),
			userinfo: at.map { .inplace(uri[start..<$0], isNormalized: userinfoIsNormalized) },
			host: .inplace(uri[(at.map { uri.index(after: $0) } ?? start)..<(colon ?? end)], isNormalized: hostIsNormalized),
			port: colon.flatMap { UInt(String(uri[uri.index(after: $0)..<end])) }
		)
	}

	// path          = path-abempty    ; begins with "/" or is empty
	//               / path-absolute   ; begins with "/" but not "//"
	//               / path-noscheme   ; begins with a non-colon segment
	//               / path-rootless   ; begins with a segment
	//               / path-empty      ; zero characters
	// 
	// path-abempty  = *( "/" segment )
	// path-absolute = "/" [ segment-nz *( "/" segment ) ]
	// path-noscheme = segment-nz-nc *( "/" segment )
	// path-rootless = segment-nz *( "/" segment )
	// path-empty    = 0<pchar>
	// 
	// segment       = *pchar
	// segment-nz    = 1*pchar
	// segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
	//               ; non-zero-length segment without any colon ":"
	// 
	// pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"
	static func parsePath(uri: String, index i: inout String.Index) throws -> Substring {
		let start = i
		var isNormalized = true
		loop: while i != uri.endIndex {
			switch uri[i] {
				case let v where unreserved(v): break
				case "?": break loop
				case "#": break loop
				case "/": break
				case ":": break
				case "@": break
				case "%": try skipPctEncoded(uri: uri, index: &i, isNormalized: &isNormalized)
				case let v where subDelims(v): break
				default: throw URIError.invalidPath
			}
			uri.formIndex(after: &i)
		}
		return uri[start..<i]
	}

	// query = *( pchar / "/" / "?" )
	static func parseQuery(uri: String, index i: inout String.Index) throws -> Substring {
		let start = i
		var isNormalized = true
		while i != uri.endIndex {
			switch uri[i] {
				case let v where unreserved(v): break
				case let v where subDelims(v): break
				case "%": try skipPctEncoded(uri: uri, index: &i, isNormalized: &isNormalized)
				case "#": return uri[start..<i]
				case "?": break
				case "/": break
				case ":": break
				case "@": break
				default: throw URIError.invalidQuery
			}
			uri.formIndex(after: &i)
		}
		return uri[start..<i]
	}

	// fragment = *( pchar / "/" / "?" )
	static func parseFragment(uri: String, index i: inout String.Index) throws -> Substring {
		let start = i
		var isNormalized = true
		while i != uri.endIndex {
			switch uri[i] {
				case let v where unreserved(v): break
				case let v where subDelims(v): break
				case "%": try skipPctEncoded(uri: uri, index: &i, isNormalized: &isNormalized)
				case "?": break
				case "/": break
				case ":": break
				case "@": break
				default: throw URIError.invalidFragment
			}
			uri.formIndex(after: &i)
		}
		return uri[start..<i]
	}

	static func validateScheme(_ scheme: String) throws -> Bool {
		var i = scheme.startIndex
		let r = try URIParser.parseScheme(uri: scheme, index: &i)
		guard i == scheme.endIndex else { throw URIError.invalidScheme }
		return r.isNormalized
	}

	// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
	static func validateUserinfo(_ userinfo: String) throws {
		var isNormalized = true
		var i = userinfo.startIndex
		while i != userinfo.endIndex {
			switch userinfo[i] {
				case ":": break
				case "%": try skipPctEncoded(uri: userinfo, index: &i, isNormalized: &isNormalized)
				case let v where unreserved(v): break
				case let v where subDelims(v): break
				default: throw URIError.invalidAuthority
			}
			userinfo.formIndex(after: &i)
		}
	}

	// host        = IP-literal / IPv4address / reg-name
	//
	// IP-literal  = "[" ( IPv6address / IPvFuture  ) "]"
	//
	// IPvFuture   = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
	//
	// IPv6address =                            6( h16 ":" ) ls32
	//             /                       "::" 5( h16 ":" ) ls32
	//             / [               h16 ] "::" 4( h16 ":" ) ls32
	//             / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
	//             / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
	//             / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
	//             / [ *4( h16 ":" ) h16 ] "::"              ls32
	//             / [ *5( h16 ":" ) h16 ] "::"              h16
	//             / [ *6( h16 ":" ) h16 ] "::"
	//
	// ls32        = ( h16 ":" h16 ) / IPv4address
	//             ; least-significant 32 bits of address
	//
	// h16         = 1*4HEXDIG
	//             ; 16 bits of address represented in hexadecimal
	//
	// IPv4address = dec-octet "." dec-octet "." dec-octet "." dec-octet
	//
	// dec-octet   = DIGIT                 ; 0-9
	//             / %x31-39 DIGIT         ; 10-99
	//             / "1" 2DIGIT            ; 100-199
	//             / "2" %x30-34 DIGIT     ; 200-249
	//             / "25" %x30-35          ; 250-255
	//
	// reg-name    = *( unreserved / pct-encoded / sub-delims )
	static func validateHost(_ host: String) throws {
		// TODO
	}

	static func validatePath(_ path: String) throws {
		var i = path.startIndex
		_ = try URIParser.parsePath(uri: path, index: &i)
		guard i == path.endIndex else { throw URIError.invalidPath }
	}

	static func validateQuery(_ query: String) throws {
		var i = query.startIndex
		_ = try URIParser.parseQuery(uri: query, index: &i)
		guard i == query.endIndex else { throw URIError.invalidQuery }
	}

	static func validateFragment(_ fragment: String) throws {
		var i = fragment.startIndex
		_ = try URIParser.parseFragment(uri: fragment, index: &i)
		guard i == fragment.endIndex else { throw URIError.invalidQuery }
	}

	// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
	static func unreserved(_ c: Character) -> Bool {
		switch c {
			case "a"..."z": return true
			case "-": return true
			case ".": return true
			case "_": return true
			case "~": return true
			case "0"..."9": return true
			case "A"..."Z": return true
			default: return false
		}
	}

	// sub-delims  = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
	static func subDelims(_ c: Character) -> Bool {
		switch c {
			case "!": return true
			case "$": return true
			case "&": return true
			case "'": return true
			case "(": return true
			case ")": return true
			case "*": return true
			case "+": return true
			case ",": return true
			case ";": return true
			case "=": return true
			default: return false
		}
	}

	// pct-encoded = "%" HEXDIG HEXDIG
	static func skipPctEncoded(uri: String, index i: inout String.Index, isNormalized: inout Bool) throws {
		var octet: UInt8 = 0
		for _ in 1...2 {
			uri.formIndex(after: &i)
			guard i != uri.endIndex else { throw URIError.invalidPctEncoded }
			let c = uri[i]
			switch c {
				case "0"..."9":
					octet = (octet << 4) | UInt8(c.unicodeScalars.first!.value - 0x30)
				case "a"..."f":
					octet = (octet << 4) | UInt8(c.unicodeScalars.first!.value - 0x57)
					// [RFC3986, section 2.1]
					// For consistency, URI producers and normalizers should use uppercase
					// hexadecimal digits for all percent-encodings.
					isNormalized = false
				case "A"..."F":
					octet = (octet << 4) | UInt8(c.unicodeScalars.first!.value - 0x37)
				default: throw URIError.invalidPctEncoded
			}
		}
		// [RFC3986, section 2.3]
		// For consistency, percent-encoded octets in the ranges of ALPHA
		// (%41-%5A and %61-%7A), DIGIT (%30-%39), hyphen (%2D), period (%2E),
		// underscore (%5F), or tilde (%7E) should not be created by URI
		// producers and, when found in a URI, should be decoded to their
		// corresponding unreserved characters by URI normalizers.
		switch octet {
			case 0x41...0x5a: fallthrough
			case 0x61...0x7a: fallthrough
			case 0x30...0x39: fallthrough
			case 0x2d: fallthrough
			case 0x2e: fallthrough
			case 0x5f: fallthrough
			case 0x7e: isNormalized = false
			default: break
		}
	}

	// pct-encoded = "%" HEXDIG HEXDIG
	static func decodePctEncoded(uri: Substring, index i: inout String.Index) -> String {
		var utf8octets = [UInt8]()
		repeat {
			uri.formIndex(after: &i)
			var octet: UInt8 = 0
			let start = i
			for _ in 1...2 {
				let c = uri[i]
				switch c {
					case "0"..."9":
						octet = (octet << 4) | UInt8(c.unicodeScalars.first!.value - 0x30)
					case "a"..."f":
						octet = (octet << 4) | UInt8(c.unicodeScalars.first!.value - 0x57)
					case "A"..."F":
						octet = (octet << 4) | UInt8(c.unicodeScalars.first!.value - 0x37)
					default:
						i = start
						return "%"
				}
				uri.formIndex(after: &i)
			}
			utf8octets.append(octet)
		} while i != uri.endIndex && uri[i] == "%"
		return String(decoding: utf8octets, as: UTF8.self)
	}
}
