// Package main provides the entry point for the svg2icon command-line tool.
//
// svg2icon converts SVG files to ICO and ICNS icon formats for Windows and macOS respectively.
//
// Usage:
//   svg2icon <input.svg> <output>
//
// The tool generates platform-specific icon files:
//   - ICO files with standard Windows icon sizes (16x16 to 256x256)
//   - ICNS files with macOS icon sizes including Retina variants
//
// Output behavior depends on the target:
//   - Directory: Creates both .ico and .icns files
//   - .ico extension: Creates Windows ICO file only
//   - .icns extension: Creates macOS ICNS file only
//   - .icon extension or no extension: Creates both formats
package main

import "github.com/julian-bruyers/svg2icon/cmd/svg2icon"

func main() {
	svg2icon.Run()
}
