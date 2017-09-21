import URI
import Foundation
import Benchmark

var a = [String]()
var b = [String]()

for _ in 0..<5 {
	timethis(count: 500000) {
		let uri = try! URI("foo://example.com:8042/over/there?name=ferret#nose")
		a.append(String(uri.scheme))
		a.append(String(uri.host!))
		a.append(String(uri.path))
		a.append(String(uri.query!))
	}
	timethis(count: 500000) {
		let uri = URL(string: "foo://example.com:8042/over/there?name=ferret#nose")!
		b.append(uri.scheme!)
		b.append(uri.host!)
		b.append(uri.path)
		b.append(uri.query!)
	}
}

print()

for _ in 0..<5 {
	timethis(count: 500000) {
		let uri = try! URI("foo://example.com:8042/over/there?name=ferret#nose")
		a.append("\(uri)")
	}
	timethis(count: 500000) {
		let uri = URL(string: "foo://example.com:8042/over/there?name=ferret#nose")!
		b.append("\(uri)")
	}
}

print(a.count)
print(b.count)
