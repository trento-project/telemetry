package server

import (
	"context"
	"strings"
	"testing"
	"time"

	influxdb2 "github.com/influxdata/influxdb-client-go/v2"
	"github.com/influxdata/influxdb-client-go/v2/domain"
	"github.com/spf13/viper"

	"github.com/stretchr/testify/suite"
)

func init() {
	viper.SetDefault("influxdb-org", "suse")
	viper.SetDefault("influxdb-bucket", "test-bucket")
	viper.SetDefault("influxdb-url", "http://localhost:8086")
	viper.SetDefault("influxdb-token", "telemetry-token")
}

type InfluxDBTestSuite struct {
	suite.Suite
	influxDBAdapter *InfluxDB
	client          influxdb2.Client
	org             string
	bucket          string
}

func TestInfluxDBTestSuite(t *testing.T) {
	suite.Run(t, new(InfluxDBTestSuite))
}

func (suite *InfluxDBTestSuite) SetupSuite() {
	suite.org = viper.GetString("influxdb-org")
	suite.bucket = viper.GetString("influxdb-bucket")
	influxDBAdapter := NewInfluxDB(
		viper.GetString("influxdb-url"),
		viper.GetString("influxdb-token"),
		suite.org,
		suite.bucket,
	)

	client := influxDBAdapter.getClient()

	suite.influxDBAdapter = influxDBAdapter
	suite.client = client
}

func (suite *InfluxDBTestSuite) TearDownSuite() {
	suite.client.Close()
}

func (suite *InfluxDBTestSuite) SetupTest() {
	cleanUpInfluxDB(suite.client, suite.org, suite.bucket)
}

func (suite *InfluxDBTestSuite) TearDownTest() {
	cleanUpInfluxDB(suite.client, suite.org, suite.bucket)
}

func cleanUpInfluxDB(client influxdb2.Client, org string, bucket string) {
	deleteAPI := client.DeleteAPI()
	deleteAPI.DeleteWithName(context.Background(), org, bucket, time.Now().Add(-240*time.Hour), time.Now(), "")
}

func (suite *InfluxDBTestSuite) TestStoreHostTelemetry() {
	err := suite.influxDBAdapter.StoreHostTelemetry([]*HostTelemetry{
		{
			InstallationID:          "uuid1",
			InstallationFlavor:      "Community",
			AgentID:                 "agent_id",
			SLESVersion:             "15.2",
			CPUCount:                16,
			SocketCount:             32,
			TotalMemoryMB:           32000,
			CloudProvider:           "azure",
			AgentInstallationSource: "Community",
			Time:                    time.Now(),
		},
		{
			InstallationID:          "uuid2",
			InstallationFlavor:      "Premium",
			AgentID:                 "agent_id_2",
			SLESVersion:             "15.2",
			CPUCount:                16,
			SocketCount:             16,
			TotalMemoryMB:           16000,
			CloudProvider:           "aws",
			AgentInstallationSource: "Premium",
			Time:                    time.Now(),
		},
	})
	suite.NoError(err)

	queryAPI := suite.client.QueryAPI(suite.org)

	delimiter := ","
	header := false
	result, err := queryAPI.QueryRaw(context.Background(),
		`from(bucket:"`+suite.bucket+`")
			|> range(start: -100000000h)
			|> filter(fn: (r) => r._measurement == "host_telemetry")
			|> filter(fn: (r) => r.agent_id == "agent_id_2")
			|> pivot(
				rowKey:["_time"],
				columnKey: ["_field"],
				valueColumn: "_value"
			)
			|> keep(columns: ["agent_id", "agent_installation_source", "installation_id", "installation_flavor", "cloud_provider", "cpu_count", "sles_version", "socket_count", "total_memory_mb"])`,
		&domain.Dialect{
			Annotations: nil,
			Delimiter:   &delimiter,
			Header:      &header,
		},
	)

	suite.NoError(err)
	suite.Equal(",_result,0,agent_id_2,uuid2,Premium,aws,16,Premium,15.2,16,16000", strings.TrimSpace(result))
}
