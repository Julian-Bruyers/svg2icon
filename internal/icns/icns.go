// Package icns provides functionality for creating macOS ICNS icon files from SVG sources.
//
// The package generates ICNS files containing multiple icon resolutions including
// standard and Retina (@2x) variants following Apple's iconset specifications.
package icns

import (
	"bytes"
	"encoding/binary"
	"os"
	"github.com/julian-bruyers/svg2icon/internal/png"
)

// StandardIconTypes defines the set of icons to be included in the .icns file.
var StandardIconTypes = []IconType{
	// Standard resolution icons (non Retina displays)
	{OSType: "icp4", Size: 16},   // 16x16
	{OSType: "icp5", Size: 32},   // 32x32
	{OSType: "icp6", Size: 64},   // 64x64
	{OSType: "ic07", Size: 128},  // 128x128
	{OSType: "ic08", Size: 256},  // 256x256
	{OSType: "ic09", Size: 512},  // 512x512
	{OSType: "ic10", Size: 1024}, // 1024x1024 (for 512x512@2x)

	// Retina (@2x) resolution icons
	{OSType: "ic11", Size: 32},  // 16x16@2x
	{OSType: "ic12", Size: 64},  // 32x32@2x
	{OSType: "ic13", Size: 256}, // 128x128@2x
	{OSType: "ic14", Size: 512}, // 256x256@2x
}

// IconType represents an ICNS icon type with its OSType code and size
type IconType struct {
	OSType   string
	Size     int
	IsRetina bool
}

// IconEntry represents a single icon entry in the ICNS file
type IconEntry struct {
	OSType [4]byte
	Length uint32
	Data   []byte
}

// CreateIcns generates a macOS ICNS file from an SVG source.
//
// The function creates a complete ICNS file containing multiple icon resolutions
// including both standard and Retina variants. The resulting file follows Apple's
// ICNS format specification and is compatible with macOS applications and Finder.
//
// Parameters:
//   - svgPath: Path to the source SVG file
//   - outputPath: Path where the ICNS file will be written
//
// Returns an error if SVG processing or file writing fails.
func CreateIcns(svgPath string, outputPath string) error {
	var entries []IconEntry

	// Generate png byte array for icon types
	for _, iconType := range StandardIconTypes {
		pngData, err := png.SvgToPng(svgPath, iconType.Size)
		if err != nil {
			return err
		}

		var osTypeBytes [4]byte
		copy(osTypeBytes[:], iconType.OSType)

		entry := IconEntry{
			OSType: osTypeBytes,
			Length: uint32(len(pngData) + 8), // Data size + 8 bytes for header (type and length)
			Data:   pngData,
		}
		entries = append(entries, entry)
	}

	// Calculate the total file size.
	// The total size starts with the 8-byte file header ('icns' + size).
	totalSize := uint32(8)
	for _, entry := range entries {
		totalSize += entry.Length
	}

	// Generate the complete ICNS file in a buffer.
	buffer := &bytes.Buffer{}

	// Write the main ICNS header.
	buffer.WriteString("icns")
	// Total file size, encoded in Big Endian byte order.
	if err := binary.Write(buffer, binary.BigEndian, totalSize); err != nil {
		return err
	}

	// Write all the icon entries.
	for _, entry := range entries {
		buffer.Write(entry.OSType[:])
		if err := binary.Write(buffer, binary.BigEndian, entry.Length); err != nil {
			return err
		}
		// Write the actual PNG data for the icon.
		buffer.Write(entry.Data)
	}

	// Write the buffer to the output file
	err := os.WriteFile(outputPath, buffer.Bytes(), 0644)
	if err != nil {
		return err
	}

	return nil
}
