// Package ico provides functionality for creating Windows ICO icon files from SVG sources.
//
// The package generates multi-resolution ICO files containing PNG-encoded images
// at standard Windows icon sizes (16x16 to 256x256 pixels).
package ico

import (
	"bytes"
	"encoding/binary"
	"github.com/julian-bruyers/svg2icon/internal/png"
	"os"
)

// The sizes used in Windows for .ico files
var IconSizes []int = []int{16, 24, 32, 48, 64, 128, 256}

// ICONDIREntry represents a single icon in the icon directory
type ICONDIREntry struct {
	Width       uint8  // Width in pixels (0 = 256)
	Height      uint8  // Height in pixels (0 = 256)
	ColorCount  uint8  // Number of colors (0 for >= 8bpp)
	Reserved    uint8  // Reserved, must be 0
	Planes      uint16 // Color planes (should be 1)
	BitCount    uint16 // Bits per pixel
	BytesInRes  uint32 // Size of image data
	ImageOffset uint32 // Offset to image data
}

// CreateIco generates a Windows ICO file from an SVG source.
//
// The function creates a multi-resolution ICO file containing PNG-encoded images
// at all standard Windows icon sizes. The resulting ICO file follows the
// Microsoft ICO format specification.
//
// Parameters:
//   - svgPath: Path to the source SVG file
//   - outputPath: Path where the ICO file will be written
//
// Returns an error if SVG processing or file writing fails.
func CreateIco(svgPath string, outputPath string) error {
	var imageData [][]byte
	var entries []ICONDIREntry

	// Generate png byte array for all sizes
	for _, currentSize := range IconSizes {
		pngData, err := png.SvgToPng(svgPath, currentSize)
		if err != nil {
			return err
		}
		imageData = append(imageData, pngData)
	}

	// Calculate offsets for image data
	headerSize := 6                    // ICONDIR header (6 bytes)
	entriesSize := len(IconSizes) * 16 // ICONDIRENTRY array (16 bytes per entry)
	currentOffset := uint32(headerSize + entriesSize)

	// Create directory entries
	for i, currentSize := range IconSizes {
		width := uint8(currentSize)
		height := uint8(currentSize)

		// ICO format uses 0 to represent 256 pixels
		if currentSize == 256 {
			width, height = 0, 0
		}

		entry := ICONDIREntry{
			Width:       width,
			Height:      height,
			ColorCount:  0,  // 0 for >= 8bpp (we use 32bpp RGBA)
			Reserved:    0,  // Always 0
			Planes:      1,  // Always 1 for PNG
			BitCount:    32, // 32bpp for RGBA PNG
			BytesInRes:  uint32(len(imageData[i])),
			ImageOffset: currentOffset,
		}
		entries = append(entries, entry)
		currentOffset += uint32(len(imageData[i]))
	}

	buffer := &bytes.Buffer{}

	// ICONDIR header
	// 2 bytes reserved, 2 bytes type=1 (icon), 2 bytes count
	binary.Write(buffer, binary.LittleEndian, uint16(0))              // reserved
	binary.Write(buffer, binary.LittleEndian, uint16(1))              // type = 1 (icon)
	binary.Write(buffer, binary.LittleEndian, uint16(len(IconSizes))) // count

	// Write ICONDIRENTRY array
	for _, currentEntry := range entries {
		binary.Write(buffer, binary.LittleEndian, currentEntry.Width)
		binary.Write(buffer, binary.LittleEndian, currentEntry.Height)
		binary.Write(buffer, binary.LittleEndian, currentEntry.ColorCount)
		binary.Write(buffer, binary.LittleEndian, currentEntry.Reserved)
		binary.Write(buffer, binary.LittleEndian, currentEntry.Planes)
		binary.Write(buffer, binary.LittleEndian, currentEntry.BitCount)
		binary.Write(buffer, binary.LittleEndian, currentEntry.BytesInRes)
		binary.Write(buffer, binary.LittleEndian, currentEntry.ImageOffset)
	}

	// Write all .png image data
	for _, currentPng := range imageData {
		buffer.Write(currentPng)
	}

	// Write the buffer to the output file
	err := os.WriteFile(outputPath, buffer.Bytes(), 0644)
	if err != nil {
		return err
	}

	return nil
}
