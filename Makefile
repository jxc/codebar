.PHONY: project build test run clean archive dmg set-secrets

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

# Create DMG from archive (local use, unsigned)
dmg: archive
	cp -R $(DERIVED_DATA)/CodeBar.xcarchive/Products/Applications/CodeBar.app $(DERIVED_DATA)/CodeBar.app
	create-dmg \
		--volname "CodeBar" \
		--window-pos 200 120 \
		--window-size 600 400 \
		--icon-size 100 \
		--icon "CodeBar.app" 150 190 \
		--app-drop-link 450 190 \
		--no-internet-enable \
		$(DERIVED_DATA)/CodeBar.dmg \
		$(DERIVED_DATA)/CodeBar.app \
	|| true
	@echo "DMG created at $(DERIVED_DATA)/CodeBar.dmg"

# Push signing secrets from .env to GitHub
set-secrets:
	@test -f .env || (echo "Error: .env not found. Copy .env.example to .env and fill in values." && exit 1)
	@. ./.env && \
	base64 -i "$$APPLE_CERTIFICATE_P12_PATH" | gh secret set APPLE_CERTIFICATE_P12 -R jxc/codebar && \
	echo "$$APPLE_CERTIFICATE_PASSWORD" | gh secret set APPLE_CERTIFICATE_PASSWORD -R jxc/codebar && \
	echo "$$APPLE_DEVELOPER_ID" | gh secret set APPLE_DEVELOPER_ID -R jxc/codebar && \
	echo "$$APPLE_APP_SPECIFIC_PASSWORD" | gh secret set APPLE_APP_SPECIFIC_PASSWORD -R jxc/codebar && \
	echo "$$APPLE_TEAM_ID" | gh secret set APPLE_TEAM_ID -R jxc/codebar && \
	echo "All 5 secrets set on jxc/codebar"
