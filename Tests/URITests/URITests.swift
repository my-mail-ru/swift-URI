import XCTest
import URI

class URITests: XCTestCase {
	static var allTests = [
		("testURI", testURI),
		("testModify", testModify),
		("testScheme", testScheme),
		("testAuthority", testAuthority),
		("testPath", testPath),
		("testQuery", testQuery),
		("testFragment", testFragment),
	]

	func testURI() {
		let uri = try! URI("foo://example.com:8042/over/there?name=ferret#nose")
		XCTAssertEqual(uri.scheme, "foo")
		XCTAssertEqual(uri.opaque, "//example.com:8042/over/there?name=ferret#nose")
		XCTAssertNil(uri.userinfo)
		XCTAssertEqual(uri.host, "example.com")
		XCTAssertEqual(uri.port, 8042)
		XCTAssertEqual(uri.path, "/over/there")
		XCTAssertEqual(uri.query, "name=ferret")
		XCTAssertEqual(uri.fragment, "nose")
		XCTAssertEqual(uri.path.segments, ["over", "there"])
		XCTAssertFalse(uri.path.isRootless)

		let file = try! URI("file:///usr/bin/vim")
		XCTAssertEqual(file.scheme, "file")
		XCTAssertEqual(file.opaque, "///usr/bin/vim")
		XCTAssertNil(file.userinfo)
		XCTAssertEqual(file.host, "")
		XCTAssertNil(file.port)
		XCTAssertEqual(file.path, "/usr/bin/vim")
		XCTAssertNil(file.query)
		XCTAssertNil(file.fragment)
		XCTAssertEqual(file.path.segments, ["usr", "bin", "vim"])
		XCTAssertFalse(file.path.isRootless)

		let ldap = try! URI("ldap://[2001:db8::7]/c=GB?objectClass?one")
		XCTAssertEqual(ldap.scheme, "ldap")
		XCTAssertEqual(ldap.opaque, "//[2001:db8::7]/c=GB?objectClass?one")
		XCTAssertNil(ldap.userinfo)
		XCTAssertEqual(ldap.host, "[2001:db8::7]")
		XCTAssertNil(ldap.port)
		XCTAssertEqual(ldap.path, "/c=GB")
		XCTAssertEqual(ldap.query, "objectClass?one")
		XCTAssertNil(ldap.fragment)
		XCTAssertEqual(ldap.path.segments, ["c=GB"])
		XCTAssertFalse(ldap.path.isRootless)

		let mail = try! URI("mailto:John.Doe@example.com")
		XCTAssertEqual(mail.scheme, "mailto")
		XCTAssertEqual(mail.opaque, "John.Doe@example.com")
		XCTAssertNil(mail.userinfo)
		XCTAssertNil(mail.host)
		XCTAssertNil(mail.port)
		XCTAssertEqual(mail.path, "John.Doe@example.com")
		XCTAssertNil(mail.query)
		XCTAssertNil(mail.fragment)
		XCTAssertEqual(mail.path.segments, ["John.Doe@example.com"])
		XCTAssertTrue(mail.path.isRootless)

		let uri2: URI = "foo://example.com:8042/over/there?name=ferret#nose"
		XCTAssertEqual(uri2.scheme, "foo")
	}

	func testModify() {
		var uri = try! URI("foo://example.com:8042/over/there?name=ferret#nose")
		uri.scheme = "https"
		uri.userinfo = "user:pass"
		uri.host = "mail.ru"
		uri.port = 8080
		uri.path = "/one/two"
		uri.query = "page=1"
		uri.fragment = "main"
		XCTAssertEqual("\(uri)", "https://user:pass@mail.ru:8080/one/two?page=1#main")
		XCTAssertEqual(uri.scheme, "https")
		XCTAssertEqual(uri.opaque, "//user:pass@mail.ru:8080/one/two?page=1#main")
		XCTAssertEqual(uri.userinfo, "user:pass")
		XCTAssertEqual(uri.host, "mail.ru")
		XCTAssertEqual(uri.port, 8080)
		XCTAssertEqual(uri.path, "/one/two")
		XCTAssertEqual(uri.query, "page=1")
		XCTAssertEqual(uri.fragment, "main")
	}

	func testScheme() {
		XCTAssertEqual(try URIScheme("http"), try URIScheme("HTTP"))
		let uriLC = try! URI("http://example.com")
		XCTAssertEqual(uriLC.scheme, "http")
		XCTAssertEqual(uriLC.scheme, "HTTP")
		let uriUC = try! URI("HTTP://example.com")
		XCTAssertEqual(uriUC.scheme, "http")
		XCTAssertEqual(uriUC.scheme, "HTTP")
	}

	func testAuthority() throws {
		var uri = try URI("http://example.com/")
		XCTAssertNil(uri.userinfo)
		XCTAssertEqual(uri.host, "example.com")
		XCTAssertNil(uri.port)
		uri = try URI("http://example.com:8080/")
		XCTAssertNil(uri.userinfo)
		XCTAssertEqual(uri.host, "example.com")
		XCTAssertEqual(uri.port, 8080)
		uri = try URI("http://userinfo@example.com:8080/")
		XCTAssertEqual(uri.userinfo, "userinfo")
		XCTAssertEqual(uri.host, "example.com")
		XCTAssertEqual(uri.port, 8080)
		uri = try URI("http://user:password@example.com:8080/")
		XCTAssertEqual(uri.userinfo, "user:password")
		XCTAssertEqual(uri.host, "example.com")
		XCTAssertEqual(uri.port, 8080)
		uri = try URI("http://user:password@example.com/")
		XCTAssertEqual(uri.userinfo, "user:password")
		XCTAssertEqual(uri.host, "example.com")
		XCTAssertNil(uri.port)
	}

	func testPath() {
		let empty = try! URI("http://example.com")
		XCTAssertEqual(empty.path.segments, [])
		XCTAssertEqual("\(empty.path)", "")
		let root = try! URI("http://example.com/")
		XCTAssertEqual(root.path.segments, [""])
		XCTAssertEqual("\(root.path)", "/")
		var uri = try! URI("http://example.com/uno/dos%20tres/%D1%87%D0%B5%D1%82%D1%8B%D1%80%D0%B5")
		XCTAssertEqual(uri.path.segments, ["uno", "dos tres", "четыре"])
		XCTAssertEqual("\(uri.path)", "/uno/dos%20tres/%D1%87%D0%B5%D1%82%D1%8B%D1%80%D0%B5")
		let rootless = try! URI("foo:uno/dos")
		XCTAssertEqual(rootless.path.segments, ["uno", "dos"])
		XCTAssertEqual("\(rootless.path)", "uno/dos")

		uri.path.segments.append("пять")
		uri.path.segments[1] = "два"
		uri.path.segments.insert("три", at: 2)
		XCTAssertEqual("\(uri.path)", "/uno/%D0%B4%D0%B2%D0%B0/%D1%82%D1%80%D0%B8/%D1%87%D0%B5%D1%82%D1%8B%D1%80%D0%B5/%D0%BF%D1%8F%D1%82%D1%8C")
		XCTAssertEqual("\(uri)", "http://example.com/uno/%D0%B4%D0%B2%D0%B0/%D1%82%D1%80%D0%B8/%D1%87%D0%B5%D1%82%D1%8B%D1%80%D0%B5/%D0%BF%D1%8F%D1%82%D1%8C")

		var path = try! URIPath("/a/%D0%B1/c")
		XCTAssertEqual("\(path)", "/a/%D0%B1/c")
		XCTAssertEqual(path.segments, ["a", "б", "c"])
		path.segments.append("d")
		XCTAssertEqual("\(path)", "/a/%D0%B1/c/d")

		XCTAssertThrowsError(try URIPath("/a/?/c"))

		XCTAssertEqual(String(URIPath(segments: ["a", "б", "c"])), "/a/%D0%B1/c")

		let path1: URIPath = "/a/%D0%B1/c"
		let path2: URIPath = ["a", "б", "c"]
		XCTAssertEqual(path1, path2)
	}

	func testQuery() {
		var uri = try! URI("http://example.com/?key=value&%D0%BA%D0%BB%D1%8E%D1%87=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%d0%bd%d0%b8%d0%b5&a+b=b+a&x%2By=y%2Bx")
		XCTAssertEqual(uri.query?.params["key"], "value")
		XCTAssertEqual(uri.query?.params["ключ"], "значение")
		XCTAssertEqual(uri.query?.params["a b"], "b a")
		XCTAssertEqual(uri.query?.params["x+y"], "y+x")
		XCTAssertEqual("\(uri.query!)", "key=value&%D0%BA%D0%BB%D1%8E%D1%87=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%d0%bd%d0%b8%d0%b5&a+b=b+a&x%2By=y%2Bx")
		uri.query!.params["newKey"] = "newValue"
		uri.query!.params["key"] = nil
		uri.query!.params["a b"] = nil
		uri.query!.params["x+y"] = nil
		uri.query!.params["ключ"] = nil
		XCTAssertEqual("\(uri)", "http://example.com/?newKey=newValue")

		var query = try! URIQuery("key=value&%D0%BA%D0%BB%D1%8E%D1%87=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%d0%bd%d0%b8%d0%b5&a+b=b+a&x%2By=y%2Bx")
		XCTAssertEqual(query.params["key"], "value")
		XCTAssertEqual(query.params["ключ"], "значение")
		XCTAssertEqual(query.params["a b"], "b a")
		XCTAssertEqual(query.params["x+y"], "y+x")
		query.params["newKey"] = "newValue"
		query.params["key"] = nil
		query.params["a b"] = nil
		query.params["x+y"] = nil
		query.params["ключ"] = nil
		XCTAssertEqual("\(query)", "newKey=newValue")

		XCTAssertThrowsError(try URIQuery("key=#value"))
	}

	func testFragment() {
//		let uri = try! URI("http://example.com/#%D1%84%D1%80%D0%B0%D0%B3%D0%BC%D0%B5%D0%BD%D1%82")
//		XCTAssertEqual(uri.fragment.decoded, "фрагмент")
	}
}
