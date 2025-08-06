// Package svg2icon provides the core functionality for converting SVG files to icon formats.
//
// This package handles command-line argument parsing, input validation, and coordinates
// the generation of ICO and ICNS icon files from SVG sources.
package svg2icon

import (
	"errors"
	"fmt"
	"github.com/julian-bruyers/svg2icon/internal/icns"
	"github.com/julian-bruyers/svg2icon/internal/ico"
	"io"
	"os"
	"path/filepath"
	"strings"
)

type PathType int

const (
	InvalidPath PathType = iota
	DirectoryPath
	FilePath
)

// Run executes the svg2icon command-line tool.
//
// It processes command-line arguments, validates input SVG files,
// and generates appropriate icon files based on the output specification.
// The function handles three output modes:
//   - Directory output: generates both ICO and ICNS files
//   - Specific format: generates only the requested format (.ico or .icns)
//   - Generic format: generates both formats with custom naming (.icon or no extension)
func Run() {
	// Validate svg2icon call arguments
	if len(os.Args) == 2 {
		switch os.Args[1] {
		case "help", "-h", "--help", "?":
			showUsage()
			os.Exit(1)
		}
	} else if len(os.Args) != 3 {
		showUsage()
		os.Exit(1)
	}

	// Validate input path (svg)
	input := os.Args[1]
	err := validSvg(input)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[svg2icon] %s\n", err)
		os.Exit(1)
	}

	// Validate output path
	output := os.Args[2]
	pathType := classifyPath(output)
	if pathType == InvalidPath {
		fmt.Fprint(os.Stderr, "[svg2icon] Invalid output filepath.\n")
		os.Exit(1)
	}

	// Generate both icons in given output directory
	if pathType == DirectoryPath {
		if output == "." {
			output = ""
		} else {
			output += "/"
		}
		output += strings.TrimSuffix(filepath.Base(input), filepath.Ext(input))

		err := ico.CreateIco(input, output+".ico")
		if err != nil {
			fmt.Fprintf(os.Stderr, "[svg2icon] %s\n", err)
		}

		err = icns.CreateIcns(input, output+".icns")
		if err != nil {
			fmt.Fprintf(os.Stderr, "[svg2icon] %s\n", err)
		}
	}

	// Generate icon(s) for given output path
	if pathType == FilePath {
		switch filepath.Ext(output) {
		case ".ico": // Only .ico
			err := ico.CreateIco(input, output)
			if err != nil {
				fmt.Fprintf(os.Stderr, "[svg2icon] %s\n", err)
			}
		case ".icns": // Only .icns
			err := icns.CreateIcns(input, output)
			if err != nil {
				fmt.Fprintf(os.Stderr, "[svg2icon] %s\n", err)
			}
		case ".icon": // Both icons with custom name
			err := ico.CreateIco(input, strings.TrimSuffix(output, filepath.Ext(output))+".ico")
			if err != nil {
				fmt.Fprintf(os.Stderr, "[svg2icon] %s\n", err)
			}

			err = icns.CreateIcns(input, strings.TrimSuffix(output, filepath.Ext(output))+".icns")
			if err != nil {
				fmt.Fprintf(os.Stderr, "[svg2icon] %s\n", err)
			}
		}
	}
}

// showUsage displays the command-line usage information to stderr.
func showUsage() {
	fmt.Fprint(os.Stderr, `
Usage:
  svg2icon <input.svg> <output>

Behavior:
  - If <output> is an existing directory, <input>.ico and <input>.icns will be created inside it.
  - If <output> ends with ".ico", only the ICO file will be generated.
  - If <output> ends with ".icns", only the ICNS file will be generated.
  - When the <output> ends with ".icon" or has no extension, both files will be created using <output> as the base name.
`)
}

// validSvg validates that the given path points to a readable SVG file.
// It checks the file extension, existence, accessibility, and basic readability.
// Returns an error if validation fails.
func validSvg(path string) error {
	extension := strings.ToLower(filepath.Ext(path))
	if extension != ".svg" {
		return errors.New("Input file must be an .svg")
	}

	pathInfo, err := os.Stat(path)
	if err != nil {
		return errors.New("Invalid input filepath.")
	}
	if pathInfo.IsDir() {
		return errors.New("Input filepath can't be a directory.")
	}

	file, err := os.Open(path)
	if err != nil {
		return errors.New("Can't open inputfile.")
	}
	defer file.Close()

	buffer := make([]byte, 1)
	if _, err := file.Read(buffer); err != nil && err != io.EOF {
		return errors.New("Can't read from inputfile.")
	}

	return nil
}

// classifyPath determines whether a path is a directory, file, or invalid.
// It returns DirectoryPath for existing directories, FilePath for valid file paths
// within existing directories, and InvalidPath for inaccessible or malformed paths.
func classifyPath(path string) PathType {
	if fileInfo, err := os.Stat(path); err == nil && fileInfo.IsDir() {
		return DirectoryPath
	}

	directory := filepath.Dir(path)
	if directory == "" {
		directory = "."
	}
	if fileInfo, err := os.Stat(directory); err != nil || !fileInfo.IsDir() {
		return InvalidPath
	}

	base := filepath.Base(path)
	extension := filepath.Ext(base)
	name := strings.TrimSuffix(base, extension)
	if name == "" || extension == "" {
		return InvalidPath
	}

	return FilePath
}
