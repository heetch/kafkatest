
// Go-centric defaults for github actions.
//
// This defines a single test job with appropriate defaults.
// Override the Platforms, Versions, RunTest and Services definitions
// for easy modification of some parameters.
package workflow

import "list"

on:   _ | *["push", "pull_request"]
name: _ | *"Test"
jobs: test: {
	strategy: matrix: {
		"go-version": _ | *[ "\(v).x" for v in Versions ]
		platform:     _ | *[ "\(p)-latest" for p in Platforms ]
	}
	"runs-on": "${{ matrix.platform }}"
	steps: list.FlattenN([{
		name: "Install Go"
		uses: "actions/setup-go@v1"
		with: "go-version": "${{ matrix.go-version }}"
	},
//	{
//		name: "Module cache"
//		uses: "actions/cache@v1"
//		with: {
//			path:           "~/go/pkg/mod"
//			key:            "${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}"
//			"restore-keys": "${{ runner.os }}-go-"
//		}
//	},
	{
		name: "Checkout code"
		uses: "actions/checkout@v1"
	},
	// Include setup steps for any services that require them,
	[ServiceConfig[name].SetupStep for name, enabled in Services if enabled && ServiceConfig[name].SetupStep != null],
	_ | *{
		name: "Test"
		run:  RunTest
	}], 1)
}

// Include all named services.
for name, enabled in Services if enabled {
	jobs: test: services: "\(name)": ServiceConfig[name].Service
}

// Platforms configures what platforms to run the tests on.
Platforms :: *["ubuntu"] | [ ... "ubuntu" | "macos" | "windows"]

// Versions configures what Go versions to run the tests on.
// TODO regexp.Match("^1.[0-9]+$")
Versions :: *["1.13"] | [ ... string]

// RunTest configures the command used to run the tests.
RunTest :: *"go test ./..." | string

// Service configures which services to make available.
// The configuration the service with name N is taken from
// ServiceConfig[N]
Services :: [_]: bool

// ServiceConfig holds the default configuration for services that
// can be started by naming them in Services.
ServiceConfig :: [_]: {
	// Service holds the contents of `jobs: test: services: "\(serviceName)"`
	"Service": Service

	// SetupStep optionally holds a step to run to set up the service
	// before the main workflow action is run (for example to wait
	// for the service to become ready).
	SetupStep: JobStep | *null
}

// Kafka requires zookeeper too.
if Services["kafka"] != _|_ {
	Services :: zookeeper: true
}

KafkaPort :: 9092

ServiceConfig :: kafka: {
	Service: {
		image: "confluentinc/cp-kafka:latest"
		ports: ["\(KafkaPort):\(KafkaPort)"]
		env: {
			// See https://docs.confluent.io/current/kafka/multi-node.html
			// for information on these settings.
			KAFKA_BROKER_ID:                        "1"
			KAFKA_ZOOKEEPER_CONNECT:                "zookeeper:2181"
			KAFKA_ADVERTISED_LISTENERS:             "interbroker://kafka:29092,fromclient://localhost:\(KafkaPort)"
			KAFKA_LISTENER_SECURITY_PROTOCOL_MAP:   "interbroker:PLAINTEXT,fromclient:PLAINTEXT"
			KAFKA_INTER_BROKER_LISTENER_NAME:       "PLAINTEXT"
			KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: "1"
		}
	}
	SetupStep: {
		name: "Wait for Kafka"
		"timeout-minutes": 1
		shell: "bash"
		run: """
			waitfor() {
				while ! nc -v -z $1 $2
				do sleep 1
				done
			}
			waitfor localhost \(KafkaPort)
			waitfor localhost 2181

			"""
	}
}

ServiceConfig :: zookeeper: {
	Service: {
		image: "confluentinc/cp-zookeeper:latest"
		ports: ["2181:2181"]
		env: {
			ZOOKEEPER_CLIENT_PORT: "2181"
			ZOOKEEPER_TICK_TIME: "2000"
		}
	}
}

ServiceConfig :: postgres: _ |*{
	Service: {
		image:   "postgres:10.8"
		ports: ["5432:5432"]
		env: {
			POSTGRES_DB:       "postgres"
			POSTGRES_PASSWORD: "postgres"
			POSTGRES_USER:     "postgres"
		}
		options: "--health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5"
	}
}
