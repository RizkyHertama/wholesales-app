package common

import (
    "context"
    "fmt"
    "log"

    "github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

// InitDB membuat koneksi pool ke Postgres
func InitDB() {
    dsn := "postgres://app:pass@localhost:5432/wholesales_db?sslmode=disable"

    var err error
    DB, err = pgxpool.New(context.Background(), dsn)
    if err != nil {
        log.Fatalf("Gagal koneksi ke database: %v", err)
    }

    // Tes koneksi
    err = DB.Ping(context.Background())
    if err != nil {
        log.Fatalf("Database tidak bisa diakses: %v", err)
    }

    fmt.Println("✅ Koneksi ke Postgres berhasil")
}
