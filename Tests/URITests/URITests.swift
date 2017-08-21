import XCTest
@testable import URI

class URITests: XCTestCase {
	static var allTests = [
		("testURI", testURI),
		("testModify", testModify),
		("testPath", testPath),
		("testQuery", testQuery),
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
		XCTAssertEqual(Array(uri.pathSegments), ["over", "there"])
		dump(uri.queryParams)
//		XCTAssertFalse(uri.pathSegments.rootless)

		let file = try! URI("file:///usr/bin/vim")
		XCTAssertEqual(file.scheme, "file")
		XCTAssertEqual(file.opaque, "///usr/bin/vim")
		XCTAssertNil(file.userinfo)
		XCTAssertEqual(file.host, "")
		XCTAssertNil(file.port)
		XCTAssertEqual(file.path, "/usr/bin/vim")
		XCTAssertNil(file.query)
		XCTAssertNil(file.fragment)
		XCTAssertEqual(Array(file.pathSegments), ["usr", "bin", "vim"])
//		XCTAssertFalse(file.pathSegments.rootless)

		let ldap = try! URI("ldap://[2001:db8::7]/c=GB?objectClass?one")
		XCTAssertEqual(ldap.scheme, "ldap")
		XCTAssertEqual(ldap.opaque, "//[2001:db8::7]/c=GB?objectClass?one")
		XCTAssertNil(ldap.userinfo)
		XCTAssertEqual(ldap.host, "[2001:db8::7]")
		XCTAssertNil(ldap.port)
		XCTAssertEqual(ldap.path, "/c=GB")
		XCTAssertEqual(ldap.query, "objectClass?one")
		XCTAssertNil(ldap.fragment)
		XCTAssertEqual(Array(ldap.pathSegments), ["c=GB"])
//		XCTAssertFalse(ldap.pathSegments.rootless)

		let mail = try! URI("mailto:John.Doe@example.com")
		XCTAssertEqual(mail.scheme, "mailto")
		XCTAssertEqual(mail.opaque, "John.Doe@example.com")
		XCTAssertNil(mail.userinfo)
		XCTAssertNil(mail.host)
		XCTAssertNil(mail.port)
		XCTAssertEqual(mail.path, "John.Doe@example.com")
		XCTAssertNil(mail.query)
		XCTAssertNil(mail.fragment)
		XCTAssertEqual(Array(mail.pathSegments), ["John.Doe@example.com"])
//		XCTAssertTrue(mail.pathSegments.rootless)
	}

	func testModify() {
		var uri = try! URI("foo://example.com:8042/over/there?name=ferret#nose")
		try! uri.set(scheme: "https")
		try! uri.set(userinfo: "user:pass")
		try! uri.set(host: "mail.ru")
		try! uri.set(port: 8080)
		try! uri.set(path: "/one/two")
		try! uri.set(query: "page=1")
		try! uri.set(fragment: "main")
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

	func testPath() {
		let empty = try! URI("http://example.com")
		XCTAssertEqual(Array(empty.pathSegments), [])
		XCTAssertEqual("\(empty.pathSegments)", "")
		let root = try! URI("http://example.com/")
		XCTAssertEqual(Array(root.pathSegments), [""])
		XCTAssertEqual("\(root.pathSegments)", "/")
		var uri = try! URI("http://example.com/uno/dos%20tres/%D1%87%D0%B5%D1%82%D1%8B%D1%80%D0%B5")
		XCTAssertEqual(Array(uri.pathSegments), ["uno", "dos tres", "четыре"])
		XCTAssertEqual("\(uri.pathSegments)", "/uno/dos%20tres/%D1%87%D0%B5%D1%82%D1%8B%D1%80%D0%B5")
		let rootless = try! URI("foo:uno/dos")
		XCTAssertEqual(Array(rootless.pathSegments), ["uno", "dos"])
		XCTAssertEqual("\(rootless.pathSegments)", "uno/dos")

		uri.pathSegments.append("пять")
		uri.pathSegments[1] = "два"
		uri.pathSegments.insert("три", at: 2)
		XCTAssertEqual("\(uri.pathSegments)", "/uno/%D0%B4%D0%B2%D0%B0/%D1%82%D1%80%D0%B8/%D1%87%D0%B5%D1%82%D1%8B%D1%80%D0%B5/%D0%BF%D1%8F%D1%82%D1%8C")
		XCTAssertEqual("\(uri)", "http://example.com/uno/%D0%B4%D0%B2%D0%B0/%D1%82%D1%80%D0%B8/%D1%87%D0%B5%D1%82%D1%8B%D1%80%D0%B5/%D0%BF%D1%8F%D1%82%D1%8C")
	}

	func testQuery() {
		let uri = try! URI("http://example.com/?key=value&%D0%BA%D0%BB%D1%8E%D1%87=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%d0%bd%d0%b8%d0%b5&a+b=b+a&x%2By=y%2Bx")
		XCTAssertEqual(uri.queryParams["key"], "value")
		XCTAssertEqual(uri.queryParams["ключ"], "значение")
		XCTAssertEqual(uri.queryParams["a b"], "b a")
		XCTAssertEqual(uri.queryParams["x+y"], "y+x")
		XCTAssertEqual("\(uri.queryParams)", "key=value&%D0%BA%D0%BB%D1%8E%D1%87=%D0%B7%D0%BD%D0%B0%D1%87%D0%B5%D0%BD%D0%B8%D0%B5&a+b=b+a&x%2By=y%2Bx")
	}
}
