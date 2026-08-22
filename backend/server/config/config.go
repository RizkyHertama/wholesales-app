package config

import (
	"fmt"
	"log"
	"os"

	"github.com/jmoiron/sqlx"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

type Config struct {
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	GRPCPort   string
	RESTPort   string
	JWTSecret  string
}

func Load() *Config {
	if err := godotenv.Load(); err != nil {
		log.Println("File .env tidak ditemukan, pakai environment variable sistem")
	}

	return &Config{
		DBHost:     os.Getenv("DB_HOST"),
		DBPort:     os.Getenv("DB_PORT"),
		DBUser:     os.Getenv("DB_USER"),
		DBPassword: os.Getenv("DB_PASSWORD"),
		DBName:     os.Getenv("DB_NAME"),
		GRPCPort:   getEnvOrDefault("GRPC_PORT", "50051"),
		RESTPort:   getEnvOrDefault("REST_PORT", "8080"),
		JWTSecret:  os.Getenv("JWT_SECRET"),
	}
}

func (c *Config) ConnectDB() (*sqlx.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		c.DBHost, c.DBPort, c.DBUser, c.DBPassword, c.DBName,
	)

	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("gagal connect database: %w", err)
	}

	// Konfigurasi connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	return db, nil
}

// Helper: ambil env, kalau kosong pakai default
func getEnvOrDefault(key, defaultVal string) string {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}
	return val
}