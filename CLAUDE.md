# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands
- Build: `swift build`
- Run all tests: `swift test`
- Run a single test: `swift test --filter "szqTests.BasicSocketTests/testSocket"`
- Run tests matching pattern: `swift test --filter "szqTests.MessageTests"`
- Lint: `swiftlint`

## Code Style Guidelines
- Swift 6 and SwiftLint compliance required
- Indentation: 2 spaces
- Naming: PascalCase for types, camelCase for variables/functions
- Imports: Sorted alphabetically, standard libraries first
- Error handling: Use Swift's throw mechanism, no force unwrapping in production code
- TODOs: Mark with `// TODO: ` and disable SwiftLint with `// swiftlint:disable:next todo`
- Test files: Use `@Suite` and `@Test` annotations with `#expect()` assertions
- Trailing commas: Preferred in multi-line collections

## Project Structure
- Library code in Sources/szq/
- Tests in Tests/szqTests/
- Executable in Sources/quickcheck/

## Platform Requirements
- macOS 14+ required
- Other platforms: See README.md for specific versions