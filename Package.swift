import PackageDescription

let package = Package(
    name: "GCloud",
    dependencies: [
		.Package(url: "https://github.com/Zewo/Zewo.git", majorVersion: 0, minor: 7),
		.Package(url: "https://github.com/VeniceX/HTTPSClient.git", majorVersion: 0, minor: 7),
		.Package(url: "https://github.com/Zewo/JSONWebToken.git", majorVersion: 0, minor: 7)
    ]
)
