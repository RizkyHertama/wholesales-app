package repository

import (
	"context"
	"database/sql"
	"errors"

	"github.com/jmoiron/sqlx"
)

// Struct yang merepresentasikan tabel companies
type Company struct {
	ID            int64   `db:"id"`
	Name          string  `db:"name"`
	Email         string  `db:"email"`
	Phone         string  `db:"phone"`
	Balance       float64 `db:"balance"`
	AccountNumber string  `db:"account_number"`
	CreatedAt     string  `db:"created_at"`
}

// Interface — daftar fungsi yang tersedia di company repository
type CompanyRepository interface {
	GetAll(ctx context.Context, page, limit int) ([]Company, int, error)
	GetByID(ctx context.Context, id int64) (*Company, error)
	UpdateBalance(ctx context.Context, id int64, newBalance float64) error
	GetByAccountNumber(ctx context.Context, accountNumber string) (*Company, error)
}

type companyRepo struct {
	db *sqlx.DB
}

func NewCompanyRepository(db *sqlx.DB) CompanyRepository {
	return &companyRepo{db: db}
}

// Ambil semua perusahaan (untuk admin)
func (r *companyRepo) GetAll(ctx context.Context, page, limit int) ([]Company, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	offset := (page - 1) * limit

	var companies []Company
	query := `
		SELECT id, name, email, phone, balance, account_number,
		       TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
		FROM companies
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`
	if err := r.db.SelectContext(ctx, &companies, query, limit, offset); err != nil {
		return nil, 0, err
	}

	var total int
	if err := r.db.GetContext(ctx, &total, "SELECT COUNT(*) FROM companies"); err != nil {
		return nil, 0, err
	}

	return companies, total, nil
}

// Ambil satu perusahaan berdasarkan ID
func (r *companyRepo) GetByID(ctx context.Context, id int64) (*Company, error) {
	var company Company
	query := `
		SELECT id, name, email, phone, balance, account_number,
		       TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
		FROM companies
		WHERE id = $1
	`
	err := r.db.GetContext(ctx, &company, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New("perusahaan tidak ditemukan")
		}
		return nil, err
	}
	return &company, nil
}

// Update saldo perusahaan
func (r *companyRepo) UpdateBalance(ctx context.Context, id int64, newBalance float64) error {
	_, err := r.db.ExecContext(ctx,
		"UPDATE companies SET balance = $1 WHERE id = $2",
		newBalance, id,
	)
	return err
}

func (r *companyRepo) GetByAccountNumber(ctx context.Context, accountNumber string) (*Company, error) {
	var company Company
	err := r.db.GetContext(ctx, &company,
		"SELECT id, name, email, phone, balance, account_number FROM companies WHERE account_number = $1",
		accountNumber,
	)
	if err != nil {
		return nil, err
	}
	return &company, nil
}
