// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "Toasts",
	platforms: [
		.iOS(.v17),
		.macOS(.v14),
	],
	products: [
		.library(name: "Toasts", targets: ["Toasts"]),
	],
	dependencies: [
		.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.0"),
	],
	targets: [
		.target(
			name: "Toasts",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
			]
		),
	]
)
