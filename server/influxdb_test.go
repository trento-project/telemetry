package server

import (
	"context"
	"strings"
	"testing"
	"time"

	influxdb2 "github.com/influxdata/influxdb-client-go/v2"
	"github.com/influxdata/influxdb-client-go/v2/domain"

	"github.com/stretchr/testify/suite"
)

type InfluxDBTestSuite struct {
	suite.Suite
	influxDBAdapter *InfluxDB
	client          influxdb2.Client
}

func TestInfluxDBTestSuite(t *testing.T) {
	suite.Run(t, new(InfluxDBTestSuite))
}

func (suite *InfluxDBTestSuite) SetupSuite() {
	influxDBAdapter := NewInfluxDB(
		"http://localhost:8086",
		"my-super-secret-auth-token",
		"test",
		"test",
	)

	client := influxDBAdapter.getClient()

	suite.influxDBAdapter = influxDBAdapter
	suite.client = client
}

func (suite *InfluxDBTestSuite) TearDownSuite() {
	suite.client.Close()
}

func (suite *InfluxDBTestSuite) SetupTest() {
	cleanUpInfluxDB(suite.client)
}

func (suite *InfluxDBTestSuite) TearDownTest() {
	cleanUpInfluxDB(suite.client)
}

func cleanUpInfluxDB(client influxdb2.Client) {
	deleteAPI := client.DeleteAPI()
	deleteAPI.DeleteWithName(context.Background(), "test", "test", time.Now().Add(-240*time.Hour), time.Now(), "")
}

func (suite *InfluxDBTestSuite) TestStoreHostTelemetry() {
	err := suite.influxDBAdapter.StoreHostTelemetry([]*HostTelemetry{
		{
			InstallationID: "uuid1",
			AgentID:        "agent_id",
			SLESVersion:    "15.2",
			CPUCount:       16,
			SocketCount:    32,
			TotalMemoryMB:  32000,
			CloudProvider:  "azure",
			Time:           time.Now(),
		},
		{
			InstallationID: "uuid2",
			AgentID:        "agent_id_2",
			SLESVersion:    "15.2",
			CPUCount:       16,
			SocketCount:    16,
			TotalMemoryMB:  16000,
			CloudProvider:  "aws",
			Time:           time.Now(),
		},
	})
	suite.NoError(err)

	queryAPI := suite.client.QueryAPI("test")

	delimiter := ","
	header := false
	result, err := queryAPI.QueryRaw(context.Background(),
		`from(bucket:"test")
			|> range(start: -100000000h)
			|> filter(fn: (r) => r._measurement == "host_telemetry")
			|> filter(fn: (r) => r.agent_id == "agent_id_2")
			|> pivot(
				rowKey:["_time"],
				columnKey: ["_field"],
				valueColumn: "_value"
			)
			|> keep(columns: ["agent_id", "installation_id", "cloud_provider", "cpu_count", "sles_version", "socket_count", "total_memory_mb"])`,
		&domain.Dialect{
			Annotations: nil,
			Delimiter:   &delimiter,
			Header:      &header,
		},
	)

	suite.NoError(err)
	suite.Equal(",_result,0,agent_id_2,uuid2,aws,16,15.2,16,16000", strings.TrimSpace(result))
}
