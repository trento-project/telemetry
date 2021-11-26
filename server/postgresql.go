package server

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/pkg/errors"
	log "github.com/sirupsen/logrus"
	"gorm.io/datatypes"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type Postgres struct {
	db *gorm.DB
}

type PostgresConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	DBName   string
}

type DBTelemetry struct {
	ID            int64          `gorm:"column:id; primaryKey"`
	Application   string         `gorm:"column:application"`
	TelemetryType string         `gorm:"column:telemetry_type"`
	Time          time.Time      `gorm:"column:time"`
	Payload       datatypes.JSON `gorm:"column:payload"`
}

func (DBTelemetry) TableName() string {
	return "telemetry"
}

func NewPostgres(config *PostgresConfig) StorageAdapter {
	db, err := initDB(config)
	if err != nil {
		log.Fatalf("failed to connect database: %s", err)
		return nil
	}
	err = migrateDB(db)
	if err != nil {
		log.Fatalf("failed to migrate database: %s", err)
		return nil
	}
	return &Postgres{db: db}
}

func (p *Postgres) StoreHostTelemetry(h []*HostTelemetry) error {
	if len(h) == 0 {
		return nil
	}
	var storableEntries []*DBTelemetry

	for _, entry := range h {
		payload, err := json.Marshal(entry)
		if err != nil {
			return errors.Wrap(err, "failed to marshal telemetry payload")
		}
		storableEntries = append(
			storableEntries,
			&DBTelemetry{
				Application:   "trento",
				TelemetryType: "host_telemetry",
				Time:          entry.Time,
				Payload:       payload,
			},
		)
	}

	err := p.db.Create(storableEntries).Error

	if err != nil {
		log.Errorf("failed to store host telemetry: %s", err)
	}

	return err
}

func initDB(config *PostgresConfig) (*gorm.DB, error) {
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		config.Host,
		config.Port,
		config.User,
		config.Password,
		config.DBName,
	)

	db, err := gorm.Open(postgres.Open(dsn))
	if err != nil {
		log.Errorf("failed to connect database: %s", err)
		return nil, errors.Wrap(err, "failed to connect database")
	}

	return db, nil
}

func migrateDB(db *gorm.DB) error {
	err := db.AutoMigrate(DBTelemetry{})

	if err != nil {
		log.Errorf("failed to migrate database: %s", err)
		return err
	}

	return nil
}
