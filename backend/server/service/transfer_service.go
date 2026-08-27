package service

import (
	"context"
	"errors"
	"fmt"

	"wholesales-app/backend/server/repository"
)

// Biaya per metode pembayaran (dalam Rupiah)
var transferFees = map[string]float64{
	"BI_FAST": 2500,
	"RTGS":    25000,
	"SKN":     2900,
}

var toCompanyID *int64

// Input untuk melakukan transfer
type TransferInput struct {
	FromCompanyID   int64
	ToAccountNumber string
	ToBankName      string
	Amount          float64
	TransferType    string // "INTERNAL" atau "EXTERNAL"
	PaymentMethod   string // "BI_FAST", "RTGS", "SKN"
	Note            string
}

// Hasil dari transfer
type TransferResult struct {
	Success          bool
	Message          string
	RemainingBalance float64
}

// Interface — daftar fungsi yang tersedia di transfer service
type TransferService interface {
	DoTransfer(ctx context.Context, input TransferInput) (*TransferResult, error)
	GetHistory(ctx context.Context, companyID int64, page, limit int) ([]repository.Transfer, int, error)
}

type transferService struct {
	transferRepo repository.TransferRepository
	companyRepo  repository.CompanyRepository
}

func NewTransferService(
	transferRepo repository.TransferRepository,
	companyRepo repository.CompanyRepository,
) TransferService {
	return &transferService{
		transferRepo: transferRepo,
		companyRepo:  companyRepo,
	}
}

// Proses transfer
func (s *transferService) DoTransfer(ctx context.Context, input TransferInput) (*TransferResult, error) {
	// Validasi minimal transfer
	if input.Amount < 10000 {
		return nil, errors.New("minimal transfer adalah Rp 10.000")
	}

	// Ambil data perusahaan pengirim
	fromCompany, err := s.companyRepo.GetByID(ctx, input.FromCompanyID)
	if err != nil {
		return nil, errors.New("perusahaan pengirim tidak ditemukan")
	}

	// Hitung biaya transfer
	// Transfer INTERNAL (sesama BRI) gratis, EXTERNAL kena biaya
	fee := 0.0
	if input.TransferType == "EXTERNAL" {
		fee = transferFees[input.PaymentMethod]
	}
	totalDeduct := input.Amount + fee

	// Cari to_company_id hanya kalau transfer INTERNAL
	if input.TransferType == "INTERNAL" {
		company, err := s.companyRepo.GetByAccountNumber(ctx, input.ToAccountNumber)
		if err != nil {
			return nil, fmt.Errorf("rekening tujuan tidak ditemukan di sistem kami")
		}
		toCompanyID = &company.ID
	}

	// Validasi saldo mencukupi
	if fromCompany.Balance < totalDeduct {
		return nil, fmt.Errorf(
			"saldo tidak mencukupi. Saldo: Rp %.0f, Dibutuhkan: Rp %.0f (termasuk biaya Rp %.0f)",
			fromCompany.Balance, totalDeduct, fee,
		)
	}

	// Validasi jika transfer type INTERNAL, Bank name harus "BRI"
	if input.TransferType == "INTERNAL" && input.ToBankName != "BRI" {
		return nil, errors.New("transfer INTERNAL hanya bisa ke bank BRI")
	}

	// Simpan record transfer ke database
	transfer := &repository.Transfer{
		FromCompanyID:   input.FromCompanyID,
		ToAccountNumber: input.ToAccountNumber,
		ToBankName:      input.ToBankName,
		Amount:          input.Amount,
		Fee:             fee,
		PaymentMethod:   input.PaymentMethod,
		TransferType:    input.TransferType,
		Status:          "SUCCESS",
		Note:            input.Note,
	}

	if err := s.transferRepo.Create(ctx, transfer); err != nil {
		return nil, fmt.Errorf("gagal menyimpan data transfer: %w", err)
	}

	// 6. Kurangi saldo pengirim
	newBalance := fromCompany.Balance - totalDeduct
	if err := s.companyRepo.UpdateBalance(ctx, input.FromCompanyID, newBalance); err != nil {
		return nil, fmt.Errorf("gagal update saldo: %w", err)
	}

	return &TransferResult{
		Success:          true,
		Message:          fmt.Sprintf("Transfer Rp %.0f berhasil. Biaya: Rp %.0f", input.Amount, fee),
		RemainingBalance: newBalance,
	}, nil
}

// Ambil history transfer
func (s *transferService) GetHistory(ctx context.Context, companyID int64, page, limit int) ([]repository.Transfer, int, error) {
	return s.transferRepo.GetByCompanyID(ctx, companyID, page, limit)
}
