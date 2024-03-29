SHELL = /bin/bash

.PHONY: linux
linux: bow-openapi-linux dependencies
		swift build

.PHONY: macos
macos: bow-openapi-macos dependencies
		swift build
		swift test --generate-linuxmain

.PHONY: xcode
xcode: dependencies
		vapor build
		swift package generate-xcodeproj 

.PHONY: dependencies
dependencies:
		@rm -rf ./Sources/Clients/AppleSignIn
		bow-openapi --name AppleSignIn --schema ./Sources/Clients/AppleSignIn.yaml --output ./Sources/Clients --verbose

.PHONY: bow-openapi-macos
bow-openapi-macos:
		brew tap bow-swift/bow
		brew install bow-openapi

.PHONY: bow-openapi-linux
bow-openapi-linux:
		curl -s https://api.github.com/repos/bow-swift/bow-openapi/releases/latest \
		| grep -oP '"tag_name": "\K(.*)(?=")' \
		| xargs -I {} wget -O - https://github.com/bow-swift/bow-openapi/archive/{}.tar.gz \
		| tar xz \
		&& make linux -C bow-openapi-*
