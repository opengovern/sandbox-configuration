package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type Benchmark struct {
	ID            string              `json:"ID" yaml:"ID"`
	Title         string              `json:"Title" yaml:"Title"`
	ReferenceCode string              `json:"ReferenceCode" yaml:"ReferenceCode"`
	Connector     string              `json:"Connector" yaml:"Connector"`
	Description   string              `json:"Description" yaml:"Description"`
	Children      []string            `json:"Children" yaml:"Children"`
	Tags          map[string][]string `json:"Tags" yaml:"Tags"`
	Managed       bool                `json:"Managed" yaml:"Managed"`
	Enabled       bool                `json:"Enabled" yaml:"Enabled"`
	AutoAssign    bool                `json:"AutoAssign" yaml:"AutoAssign"`
	Baseline      bool                `json:"Baseline" yaml:"Baseline"`
	Controls      []string            `json:"Controls" yaml:"Controls"`
}

type Control struct {
	ID string `json:"ID" yaml:"ID"`
}

var (
	BenchmarksPath = os.Getenv("BENCHMARKS_PATH")
	ControlsPath   = os.Getenv("CONTROLS_PATH")

	red   = "\033[31m"
	green = "\033[32m"
	reset = "\033[0m"
	bold  = "\033[1m"
)

func main() {
	benchmarksControls := getBenchmarkControls(BenchmarksPath)
	controlsList := getControls(ControlsPath)

	compareControls(benchmarksControls, controlsList)
}

// getBenchmarkControls parses all benchmark YAML files and returns a list of control IDs
func getBenchmarkControls(root string) []string {
	var controls []string

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if strings.HasSuffix(info.Name(), ".yaml") {
			benchmark := parseBenchmarkFile(path)
			controls = append(controls, benchmark.Controls...)

		}
		return nil
	})

	if err != nil {
		log.Fatalf("Error walking through benchmark directory: %v", err)
	}

	return controls
}

// parseBenchmarkFile parses a YAML file into a slice of Benchmark structs
func parseBenchmarkFile(filePath string) Benchmark {
	file, err := os.ReadFile(filePath)
	if err != nil {
		log.Fatalf("Error reading benchmark file: %v", err)
	}

	var benchmarks Benchmark
	err = yaml.Unmarshal(file, &benchmarks)
	if err != nil {
		log.Fatalf("Error unmarshalling benchmark YAML: %v", err)
	}

	return benchmarks
}

// getControls parses all control YAML files and returns a list of control IDs
func getControls(root string) []string {
	var controls []string

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if strings.HasSuffix(info.Name(), ".yaml") {
			control := parseControlFile(path)
			if control.ID != "" {
				controls = append(controls, control.ID)
			}
		}
		return nil
	})

	if err != nil {
		log.Fatalf("Error walking through controls directory: %v", err)
	}

	return controls
}

// parseControlFile parses a YAML file into a Control struct
func parseControlFile(filePath string) Control {
	file, err := os.ReadFile(filePath)
	if err != nil {
		log.Fatalf("Error reading control file: %v", err)
	}

	var control Control
	err = yaml.Unmarshal(file, &control)
	if err != nil {
		log.Fatalf("Error unmarshalling control YAML: %v", err)
	}

	return control
}

// compareControls compares the benchmark controls with the controls list and prints differences
func compareControls(benchmarkControls, controlList []string) {
	benchmarkControlSet := make(map[string]bool)
	controlSet := make(map[string]bool)

	for _, control := range benchmarkControls {
		benchmarkControlSet[control] = true
	}

	for _, control := range controlList {
		controlSet[control] = true
	}

	fmt.Println(bold + "Controls in benchmarks but not in controls:" + reset)
	for control := range benchmarkControlSet {
		if !controlSet[control] {
			fmt.Println(string(green) + " + " + string(reset) + control)
		}
	}

	fmt.Println(bold + "Controls in controls but not in benchmarks:" + reset)
	for control := range controlSet {
		if !benchmarkControlSet[control] {
			fmt.Println(string(red) + " - " + string(reset) + control)
		}
	}
}
