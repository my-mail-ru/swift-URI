enum URIError : Error {
	case invalidScheme
	case invalidAuthority
	case invalidPath
	case invalidQuery
	case invalidFragment
	case invalidPctEncoded
}
