SHELL = /bin/bash

.PHONY: build
build:
		bow-openapi --name AppleSignIn --schema Sources/Clients/AppleSignIn.yaml --output Sources/Clients/AppleSignIn
		vapor xcode -n
		swift test --generate-linuxmain
