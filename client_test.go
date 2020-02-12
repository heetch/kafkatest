package main

import (
	"os"
	"testing"
)

func TestFoo(t *testing.T) {
	err := DialIt(os.Getenv("KAFKA_ADDRS"))
	if err != nil {
		t.Errorf("cannot dial %q: %v", os.Getenv("KAFKA_ADDRS"), err)
	}
}
