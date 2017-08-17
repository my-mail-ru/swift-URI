// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription

let buildBenchmark = false

let package = Package(
	name: "URI",
	products: [
		.library(name: "URI", targets: ["URI"]),
	],
	targets: [
		.target(name: "URI", dependencies: []),
		.testTarget(name: "URITests", dependencies: ["URI"]),
	]
)

if buildBenchmark {
	package.dependencies.append(.package(url: "https://github.com/my-mail-ru/swift-Benchmark.git", from: "0.3.0"))
	package.targets.append(.target(name: "uri-benchmark", dependencies: ["URI", "Benchmark"]))
}
