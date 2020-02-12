package kafkatest_test

import (
	"net"
	"os"
	"testing"

	_ "github.com/heetch/kafkatest"
)

func TestFoo(t *testing.T) {
	_, err := net.Dial("tcp", os.Getenv("KAFKA_ADDRS"))
	if err != nil {
		t.Errorf("cannot dial: %v", err)
	}
}
