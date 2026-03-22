.PHONY: project build test run clean archive

DERIVED_DATA = .build
APP_PATH = $(DERIVED_DATA)/Build/Products/Debug/CodeBar.app

# Regenerate Xcode project from project.yml
project:
	xcodegen generate

# Build the app
build: project
	xcodebuild -project CodeBar.xcodeproj -scheme CodeBar -configuration Debug -derivedDataPath $(DERIVED_DATA) build

# Run tests
test: project
	xcodebuild -project CodeBar.xcodeproj -scheme CodeBar -configuration Debug -derivedDataPath $(DERIVED_DATA) test

# Build and run
run: build
	open $(APP_PATH)

# Clean build artifacts
clean:
	xcodebuild -project CodeBar.xcodeproj -scheme CodeBar clean 2>/dev/null || true
	rm -rf $(DERIVED_DATA)

# Archive for release
archive: project
	xcodebuild -project CodeBar.xcodeproj -scheme CodeBar -configuration Release -derivedDataPath $(DERIVED_DATA) archive -archivePath $(DERIVED_DATA)/CodeBar.xcarchive
