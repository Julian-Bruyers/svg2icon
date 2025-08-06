// Package png provides SVG to PNG conversion functionality for icon generation.
//
// This package handles the rasterization of SVG files into PNG format at specific
// pixel dimensions, serving as the foundation for ICO and ICNS icon generation.
package png

import (
	"bytes"
	"image"
	"image/png"
	"os"

	"github.com/srwiley/oksvg"
	"github.com/srwiley/rasterx"
)

// SvgToPng converts an SVG file to PNG format at the specified pixel size.
//
// The function rasterizes the SVG using vector graphics processing to produce
// high-quality PNG output suitable for icon generation. The SVG is scaled to
// fit exactly within the specified square dimensions.
//
// Parameters:
//   - svgPath: Path to the source SVG file
//   - pxSize: Output dimensions in pixels (width and height)
//
// Returns the PNG-encoded image data as bytes, or an error if conversion fails.
func SvgToPng(svgPath string, pxSize int) ([]byte, error) {
	svgFile, err := os.Open(svgPath)
	if err != nil {
		return nil, err
	}
	defer svgFile.Close()

	icon, err := oksvg.ReadIconStream(svgFile)
	if err != nil {
		return nil, err
	}

	canvas := image.NewRGBA(image.Rect(0, 0, pxSize, pxSize))
	icon.SetTarget(0, 0, float64(pxSize), float64(pxSize))

	scanner := rasterx.NewScannerGV(pxSize, pxSize, canvas, canvas.Bounds())
	raster := rasterx.NewDasher(pxSize, pxSize, scanner)
	icon.Draw(raster, 1.0)

	var buffer bytes.Buffer
	if err := png.Encode(&buffer, canvas); err != nil {
		return nil, err
	}
	return buffer.Bytes(), nil
}
