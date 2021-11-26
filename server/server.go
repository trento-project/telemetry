package server

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

func init() {
	viper.SetEnvKeyReplacer(strings.NewReplacer("-", "_", ".", "_"))
	viper.SetEnvPrefix("TELEMETRY")
	viper.AutomaticEnv()

	viper.SetDefault("influxdb-org", "suse")
	viper.SetDefault("influxdb-bucket", "telemetry")
	viper.SetDefault("influxdb-url", "http://localhost:8086")
	viper.SetDefault("influxdb-token", "telemetry-token")

	viper.SetDefault("db-host", "localhost")
	viper.SetDefault("db-port", 5432)
	viper.SetDefault("db-user", "telemetry_user")
	viper.SetDefault("db-password", "averystrongpassword")
	viper.SetDefault("db-name", "telemetry")
}

//go:generate mockery --name=StorageAdapter --inpackage --filename=storage_adapter_mock.go
type StorageAdapter interface {
	StoreHostTelemetry([]*HostTelemetry) error
}

type HostTelemetry struct {
	InstallationID string    `json:"installation_id"`
	AgentID        string    `json:"agent_id"`
	SLESVersion    string    `json:"sles_version"`
	CPUCount       int       `json:"cpu_count"`
	SocketCount    int       `json:"socket_count"`
	TotalMemoryMB  int       `json:"total_memory_mb"`
	CloudProvider  string    `json:"cloud_provider"`
	Time           time.Time `json:"time"`
}

func pingHandler() func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "pong")
	}
}

func hostTelemetryHandler(adapters ...StorageAdapter) func(w http.ResponseWriter, r *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		var hostTelemetryEntries []*HostTelemetry
		err := json.NewDecoder(r.Body).Decode(&hostTelemetryEntries)
		if err != nil {
			log.Errorf("Error unmarshaling host telemetry: %v", err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		for _, h := range hostTelemetryEntries {
			log.Debugf("Received new host telemetry data: %+v", h)
		}

		for _, adapter := range adapters {
			if err := adapter.StoreHostTelemetry(hostTelemetryEntries); err != nil {
				log.Errorf("Error storing host telemetry: %v", err)
				w.WriteHeader(http.StatusInternalServerError)
				return
			}
		}

		w.WriteHeader(http.StatusAccepted)
	}
}

func HandleRequests() {
	influxDBAdapter := NewInfluxDB(
		viper.GetString("influxdb-url"),
		viper.GetString("influxdb-token"),
		viper.GetString("influxdb-org"),
		viper.GetString("influxdb-bucket"),
	)
	postgresAdapter := NewPostgres(
		&PostgresConfig{
			Host:     viper.GetString("db-host"),
			Port:     viper.GetInt("db-port"),
			User:     viper.GetString("db-user"),
			Password: viper.GetString("db-password"),
			DBName:   viper.GetString("db-name"),
		},
	)

	http.HandleFunc("/api/ping", pingHandler())
	http.HandleFunc("/api/collect/hosts", hostTelemetryHandler(influxDBAdapter, postgresAdapter))

	log.Infof("Starting Trento telemetry server...")
	log.Fatal(http.ListenAndServe(":10000", nil))
}
