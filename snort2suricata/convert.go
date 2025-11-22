package main

import (
	"bufio"
	"fmt"
	"os"

	"github.com/google/gonids"
)

func main() {
	f, err := os.Open("rule.txt")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening file: %v\n", err)
		return
	}
	defer f.Close()
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		rule := string(line)
		r, err := gonids.ParseRule(rule)
		if err != nil {
			// Handle parse error
			continue
		}
		// r.OptimizeHTTP()
		fmt.Println(r)
	}
}
