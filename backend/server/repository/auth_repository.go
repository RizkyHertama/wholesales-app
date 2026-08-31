package repository

import (
	"context"
	"database/sql"
	"errors"
	"log"

	"github.com/jmoiron/sqlx"
)

// Struct yang merepresentasikan tabel companies (untuk keperluan auth)
type CompanyAuth struct {
	ID            int64  `db:"id"`
	Name          string `db:"name"`
	Email         string `db:"email"`
	PasswordHash  string `db:"password_hash"`
	AccountNumber string `db:"account_number"`
}

// Interface — daftar fungsi yang tersedia di auth repository
type AuthRepository interface {
	FindByEmail(ctx context.Context, email string) (*CompanyAuth, error)
	Create(ctx context.Context, name, email, passwordHash, phone, accountNumber string) error
	EmailExists(ctx context.Context, email string) (bool, error)
}

type authRepo struct {
	db *sqlx.DB
}

func NewAuthRepository(db *sqlx.DB) AuthRepository {
	return &authRepo{db: db}
}

// Cari perusahaan berdasarkan email (untuk login)
func (r *authRepo) FindByEmail(ctx context.Context, email string) (*CompanyAuth, error) {
	var company CompanyAuth
	query := `SELECT id, name, email, password_hash, account_number FROM companies WHERE email = $1`

	err := r.db.GetContext(ctx, &company, query, email)

	log.Printf("Company", company)
	log.Printf("Query", query)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New("email tidak ditemukan")
		}
		return nil, err
	}

	return &company, nil
}

// Buat akun perusahaan baru (untuk register)
func (r *authRepo) Create(ctx context.Context, name, email, passwordHash, phone, accountNumber string) error {
	query := `
		INSERT INTO companies (name, email, password_hash, phone, account_number, balance)
		VALUES ($1, $2, $3, $4, $5, 0)
	`
	_, err := r.db.ExecContext(ctx, query, name, email, passwordHash, phone, accountNumber)
	return err
}

// Cek apakah email sudah terdaftar
func (r *authRepo) EmailExists(ctx context.Context, email string) (bool, error) {
	var count int
	err := r.db.GetContext(ctx, &count, "SELECT COUNT(*) FROM companies WHERE email = $1", email)
	return count > 0, err
}
