package repository

import (
	"context"

	"github.com/jmoiron/sqlx"
)

// Struct yang merepresentasikan tabel transfers
type Transfer struct {
	ID              int64   `db:"id"`
	FromCompanyID   int64   `db:"from_company_id"`
	ToCompanyID     *int64  `db:"to_company_id"` // pakai pointer, bisa nil
	ToAccountNumber string  `db:"to_account_number"`
	ToBankName      string  `db:"to_bank_name"`
	Amount          float64 `db:"amount"`
	Fee             float64 `db:"fee"`
	PaymentMethod   string  `db:"payment_method"`
	TransferType    string  `db:"transfer_type"`
	Status          string  `db:"status"`
	Note            string  `db:"note"`
	CreatedAt       string  `db:"created_at"`
}

// Interface — daftar fungsi yang tersedia di transfer repository
type TransferRepository interface {
	Create(ctx context.Context, t *Transfer) error
	GetByCompanyID(ctx context.Context, companyID int64, page, limit int) ([]Transfer, int, error)
}

type transferRepo struct {
	db *sqlx.DB
}

func NewTransferRepository(db *sqlx.DB) TransferRepository {
	return &transferRepo{db: db}
}

// Simpan data transfer baru ke database
func (r *transferRepo) Create(ctx context.Context, t *Transfer) error {
	query := `
		INSERT INTO transfers
			(from_company_id, to_company_id, to_account_number, to_bank_name,
			 amount, fee, payment_method, transfer_type, status, note)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err := r.db.ExecContext(ctx, query,
		t.FromCompanyID, t.ToCompanyID, t.ToAccountNumber, t.ToBankName,
		t.Amount, t.Fee, t.PaymentMethod, t.TransferType, t.Status, t.Note,
	)
	return err
}

// Ambil history transfer milik sebuah perusahaan
func (r *transferRepo) GetByCompanyID(ctx context.Context, companyID int64, page, limit int) ([]Transfer, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	offset := (page - 1) * limit

	var transfers []Transfer
	query := `
		SELECT id, from_company_id, to_company_id, to_account_number, to_bank_name,
		       amount, fee, payment_method, transfer_type, status, note,
		       TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
		FROM transfers
		WHERE from_company_id = $1 OR to_company_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	if err := r.db.SelectContext(ctx, &transfers, query, companyID, limit, offset); err != nil {
		return nil, 0, err
	}

	var total int
	r.db.GetContext(ctx, &total,
		"SELECT COUNT(*) FROM transfers WHERE from_company_id=$1 OR to_company_id=$1",
		companyID,
	)

	return transfers, total, nil
}
