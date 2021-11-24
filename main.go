package main

import (
	"os"

	log "github.com/sirupsen/logrus"
	server "github.com/trento-project/telemetry/server"
)

func main() {
	if os.Getenv("TELEMETRY_DEBUG") == "true" {
		log.SetLevel(log.DebugLevel)
	}

	server.HandleRequests()
}
