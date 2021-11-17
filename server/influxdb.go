package server

import (
	"context"

	influxdb2 "github.com/influxdata/influxdb-client-go/v2"
)

const (
	org                      = "trento"
	bucket                   = "telemetry"
	hostTelemetryMeasurement = "host_telemetry"
)

type InfluxDB struct {
	url   string
	token string
}

func NewInfluxDB(url string, token string) *InfluxDB {
	return &InfluxDB{url: url, token: token}
}

func (i *InfluxDB) StoreHostTelemetry(h *HostTelemetry) error {
	client := i.getClient()
	writeAPI := client.WriteAPIBlocking(org, bucket)
	defer client.Close()

	p := influxdb2.NewPointWithMeasurement(hostTelemetryMeasurement).
		AddTag("agent_id", h.AgentID).
		AddField("sles_version", h.SLESVersion).
		AddField("cpu_count", h.CPUCount).
		AddField("socket_count", h.SocketCount).
		AddField("total_memory_mb", h.TotalMemoryMB).
		AddField("cloud_provider", h.CloudProvider).
		SetTime(h.Time)

	return writeAPI.WritePoint(context.Background(), p)
}

func (i *InfluxDB) getClient() influxdb2.Client {
	return influxdb2.NewClient(i.url, i.token)
}
