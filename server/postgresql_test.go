package server

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/spf13/viper"
	"github.com/stretchr/testify/suite"
	"gorm.io/gorm"
)

func init() {
	viper.SetDefault("db-host", "localhost")
	viper.SetDefault("db-port", 5432)
	viper.SetDefault("db-user", "test")
	viper.SetDefault("db-password", "test")
	viper.SetDefault("db-name", "test")
}

type PostgresqlTestSuite struct {
	suite.Suite
	db *gorm.DB
	tx *gorm.DB
}

func TestPostgresqlTestSuite(t *testing.T) {
	suite.Run(t, new(PostgresqlTestSuite))
}

func (suite *PostgresqlTestSuite) SetupSuite() {
	db, err := initDB(dbConfig())
	if err != nil {
		suite.T().Fatal("could not open test database connection")
		return
	}
	suite.db = db
}

func (suite *PostgresqlTestSuite) TearDownSuite() {
	suite.db.Migrator().DropTable(DBTelemetry{})
}

func (suite *PostgresqlTestSuite) SetupTest() {
	suite.tx = suite.db.Begin()
}

func (suite *PostgresqlTestSuite) TearDownTest() {
	suite.tx.Rollback()
}

func (suite *PostgresqlTestSuite) Test_StoresOnDatabase() {
	postgresAdapter := NewPostgres(dbConfig())
	incomingHostTelemetries := dummyIncomingHostTelemetries()

	err := postgresAdapter.StoreHostTelemetry(incomingHostTelemetries)
	suite.NoError(err)

	var storedTelemetries []DBTelemetry
	err = suite.tx.Find(&storedTelemetries).Error

	suite.NoError(err)
	suite.Equal(5, len(storedTelemetries))

	for i, storedTelemetry := range storedTelemetries {
		suite.EqualValues(i+1, storedTelemetry.ID)
		suite.EqualValues("trento", storedTelemetry.Application)
		suite.EqualValues("host_telemetry", storedTelemetry.TelemetryType)

		encodedPayload, _ := json.Marshal(incomingHostTelemetries[i])

		suite.JSONEq(string(encodedPayload), string(storedTelemetry.Payload))
	}
}

func dbConfig() *PostgresConfig {
	return &PostgresConfig{
		Host:     viper.GetString("db-host"),
		Port:     viper.GetInt("db-port"),
		User:     viper.GetString("db-user"),
		Password: viper.GetString("db-password"),
		DBName:   viper.GetString("db-name"),
	}
}

func dummyIncomingHostTelemetries() []*HostTelemetry {
	return []*HostTelemetry{
		{
			InstallationID:          "installation-id",
			InstallationFlavor:      "Community",
			AgentID:                 "agent-1",
			SLESVersion:             "15-SP2",
			CPUCount:                4,
			SocketCount:             2,
			TotalMemoryMB:           4096,
			CloudProvider:           "aws",
			AgentInstallationSource: "Community",
			Time:                    time.Now(),
		},
		{
			InstallationID:          "installation-id",
			InstallationFlavor:      "Premium",
			AgentID:                 "agent-2",
			SLESVersion:             "15-SP2",
			CPUCount:                4,
			SocketCount:             2,
			TotalMemoryMB:           4096,
			CloudProvider:           "aws",
			AgentInstallationSource: "Premium",
			Time:                    time.Now(),
		},
		{
			InstallationID:          "installation-id",
			InstallationFlavor:      "Community",
			AgentID:                 "agent-3",
			SLESVersion:             "15-SP2",
			CPUCount:                4,
			SocketCount:             2,
			TotalMemoryMB:           4096,
			CloudProvider:           "aws",
			AgentInstallationSource: "Community",
			Time:                    time.Now(),
		},
		{
			InstallationID:          "installation-id",
			InstallationFlavor:      "Premium",
			AgentID:                 "agent-4",
			SLESVersion:             "15-SP2",
			CPUCount:                4,
			SocketCount:             2,
			TotalMemoryMB:           4096,
			CloudProvider:           "aws",
			AgentInstallationSource: "Premium",
			Time:                    time.Now(),
		},
		{
			InstallationID:          "installation-id",
			InstallationFlavor:      "Community",
			AgentID:                 "agent-5",
			SLESVersion:             "15-SP2",
			CPUCount:                4,
			SocketCount:             2,
			TotalMemoryMB:           4096,
			CloudProvider:           "aws",
			AgentInstallationSource: "Community",
			Time:                    time.Now(),
		},
	}
}
