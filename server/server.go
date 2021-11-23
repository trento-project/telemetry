package server

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	log "github.com/sirupsen/logrus"
)

//go:generate mockery --name=StorageAdapter --inpackage --filename=storage_adapter_mock.go
type StorageAdapter interface {
	StoreHostTelemetry(*HostTelemetry) error
}

type HostTelemetry struct {
	AgentID       string    `json:"agent_id"`
	SLESVersion   string    `json:"sles_version"`
	CPUCount      int       `json:"cpu_count"`
	SocketCount   int       `json:"socket_count"`
	TotalMemoryMB int       `json:"total_memory_mb"`
	CloudProvider string    `json:"cloud_provider"`
	Time          time.Time `json:"time"`
}

func pingHandler() func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "pong")
		return
	}
}

func hostTelemetryHandler(adapters ...StorageAdapter) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		var hostTelemetry HostTelemetry
		err := json.NewDecoder(r.Body).Decode(&hostTelemetry)
		if err != nil {
			log.Errorf("Error unmarshaling host telemetry: %v", err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		log.Debugf("Received new host telemetry data from agent: %s", hostTelemetry.AgentID)
		for _, adapter := range adapters {
			if err := adapter.StoreHostTelemetry(&hostTelemetry); err != nil {
				log.Errorf("Error storing host telemetry: %v", err)
			}
		}

		w.WriteHeader(http.StatusAccepted)
	}
}

func HandleRequests() {
	influxDBAdapter := NewInfluxDB(
		os.Getenv("TELEMETRY_INFLUXDB_URL"),
		os.Getenv("TELEMETRY_INFLUXDB_TOKEN"),
		os.Getenv("TELEMETRY_INFLUXDB_ORG"),
		os.Getenv("TELEMETRY_INFLUXDB_BUCKET"))

	http.HandleFunc("/api/ping", pingHandler())
	http.HandleFunc("/api/collect/hosts", hostTelemetryHandler(influxDBAdapter))

	log.Infof("Starting Trento telemetry server...")
	log.Fatal(http.ListenAndServe(":10000", nil))
}
