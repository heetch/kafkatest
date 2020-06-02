//+build ignore

package main

import (
	"fmt"
	"net"
	"os"
)

func main() {
	_, err := net.Dial("tcp", os.Args[1])
	fmt.Printf("dial %s: %v\n", os.Args[1], err)
	if err != nil {
		os.Exit(1)
	}
}
