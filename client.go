package main

import (
	"fmt"
	"net"
	"os"
)

func main() {
	err := DialIt(os.Args[1])
	fmt.Printf("dial %s: %v\n", os.Args[1], err)
	if err != nil {
		os.Exit(1)
	}
}

func DialIt(s string) error {
	_, err := net.Dial("tcp", s)
	if err != nil {
		return fmt.Errorf("dialit: %v", err)
	}
	return nil
}
