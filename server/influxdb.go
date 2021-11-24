package server

import (
	"context"

	influxdb2 "github.com/influxdata/influxdb-client-go/v2"
	"github.com/pkg/errors"
)

const (
	hostTelemetryMeasurement = "host_telemetry"
)

type InfluxDB struct {
	url    string
	token  string
	org    string
	bucket string
}

func NewInfluxDB(url string, token string, org string, bucket string) *InfluxDB {
	return &InfluxDB{url: url, token: token, org: org, bucket: bucket}
}

func (i *InfluxDB) StoreHostTelemetry(h []*HostTelemetry) error {
	client := i.getClient()
	writeAPI := client.WriteAPIBlocking(i.org, i.bucket)
	defer client.Close()

	var err error
	for _, t := range h {
		p := influxdb2.NewPointWithMeasurement(hostTelemetryMeasurement).
			AddTag("agent_id", t.AgentID).
			AddField("sles_version", t.SLESVersion).
			AddField("cpu_count", t.CPUCount).
			AddField("socket_count", t.SocketCount).
			AddField("total_memory_mb", t.TotalMemoryMB).
			AddField("cloud_provider", t.CloudProvider).
			SetTime(t.Time)

		e := writeAPI.WritePoint(context.Background(), p)
		if e != nil {
			errors.Wrap(err, e.Error())
		}
	}
	return err
}

func (i *InfluxDB) getClient() influxdb2.Client {
	return influxdb2.NewClient(i.url, i.token)
}
