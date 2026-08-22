package service

import (
	"context"
	"errors"
	"fmt"

	"wholesales-app/backend/server/repository"
)

// Input untuk top up saldo
type TopUpInput struct {
	CompanyID int64
	Amount    float64
	Note      string
}

// Hasil dari top up
type TopUpResult struct {
	NewBalance float64
	Message    string
}

// Interface — daftar fungsi yang tersedia di company service
type CompanyService interface {
	GetCompanyList(ctx context.Context, page, limit int) ([]repository.Company, int, error)
	GetCompanyDetail(ctx context.Context, id int64) (*repository.Company, error)
	TopUp(ctx context.Context, input TopUpInput) (*TopUpResult, error)
	GetBalance(ctx context.Context, companyID int64) (float64, string, error)
}

type companyService struct {
	companyRepo repository.CompanyRepository
}

func NewCompanyService(companyRepo repository.CompanyRepository) CompanyService {
	return &companyService{companyRepo: companyRepo}
}

// Ambil daftar semua perusahaan (untuk admin)
func (s *companyService) GetCompanyList(ctx context.Context, page, limit int) ([]repository.Company, int, error) {
	return s.companyRepo.GetAll(ctx, page, limit)
}

// Ambil detail satu perusahaan
func (s *companyService) GetCompanyDetail(ctx context.Context, id int64) (*repository.Company, error) {
	return s.companyRepo.GetByID(ctx, id)
}

// Top up saldo perusahaan
func (s *companyService) TopUp(ctx context.Context, input TopUpInput) (*TopUpResult, error) {
	// 1. Validasi minimal top up
	if input.Amount < 10000 {
		return nil, errors.New("minimal top up adalah Rp 10.000")
	}

	// 2. Ambil saldo saat ini
	company, err := s.companyRepo.GetByID(ctx, input.CompanyID)
	if err != nil {
		return nil, fmt.Errorf("perusahaan tidak ditemukan: %w", err)
	}

	// 3. Hitung saldo baru
	newBalance := company.Balance + input.Amount

	// 4. Update saldo di database
	if err := s.companyRepo.UpdateBalance(ctx, input.CompanyID, newBalance); err != nil {
		return nil, fmt.Errorf("gagal update saldo: %w", err)
	}

	return &TopUpResult{
		NewBalance: newBalance,
		Message:    fmt.Sprintf("Top up Rp %.0f berhasil", input.Amount),
	}, nil
}

// Ambil saldo dan nomor rekening perusahaan
func (s *companyService) GetBalance(ctx context.Context, companyID int64) (float64, string, error) {
	company, err := s.companyRepo.GetByID(ctx, companyID)
	if err != nil {
		return 0, "", err
	}
	return company.Balance, company.AccountNumber, nil
}
