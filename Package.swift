import PackageDescription

let package = Package(
    name: "GCloud",
    dependencies: [
		.Package(url: "https://github.com/Zewo/Core.git", majorVersion: 0, minor: 13),
		.Package(url: "https://github.com/Zewo/HTTPClient.git", majorVersion: 0, minor: 13),
		.Package(url: "https://github.com/Zewo/JSONWebToken.git", majorVersion: 0, minor: 13)
    ]
)
