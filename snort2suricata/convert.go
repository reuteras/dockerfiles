package main

import (
    "github.com/google/gonids"
    "bufio"
    "os"
    "fmt"
)

func main() {  
	f, _ := os.Open("rule.txt")
    scanner := bufio.NewScanner(f)
    for scanner.Scan() {
        line := scanner.Text()
    	rule :=  string(line)
	    r, err := gonids.ParseRule(rule)
    	if err != nil {
        	// Handle parse error
    	}
        // r.OptimizeHTTP()
    	fmt.Println(r)
    }
}
