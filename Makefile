.PHONY: project build test run clean archive

# Regenerate Xcode project from project.yml
project:
	xcodegen generate

# Build the app
build: project
	xcodebuild -project CodeBar.xcodeproj -scheme CodeBar -configuration Debug build

# Run tests
test: project
	xcodebuild -project CodeBar.xcodeproj -scheme CodeBar -configuration Debug test

# Build and run
run: build
	open build/Build/Products/Debug/CodeBar.app

# Clean build artifacts
clean:
	xcodebuild -project CodeBar.xcodeproj -scheme CodeBar clean 2>/dev/null || true
	rm -rf build/ DerivedData/

# Archive for release
archive: project
	xcodebuild -project CodeBar.xcodeproj -scheme CodeBar -configuration Release archive -archivePath build/CodeBar.xcarchive
