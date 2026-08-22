package service

import (
	"context"
	"errors"
	"fmt"

	"wholesales-app/backend/server/repository"
	"wholesales-app/backend/server/utils"
)

// Input untuk login
type LoginInput struct {
	Email    string
	Password string
}

// Hasil dari login
type LoginResult struct {
	Token       string
	CompanyName string
	CompanyID   int64
}

// Input untuk register
type RegisterInput struct {
	CompanyName string
	Email       string
	Password    string
	Phone       string
}

// Interface — daftar fungsi yang tersedia di auth service
type AuthService interface {
	Login(ctx context.Context, input LoginInput) (*LoginResult, error)
	Register(ctx context.Context, input RegisterInput) error
}

type authService struct {
	authRepo  repository.AuthRepository
	jwtSecret string
}

func NewAuthService(authRepo repository.AuthRepository, jwtSecret string) AuthService {
	return &authService{
		authRepo:  authRepo,
		jwtSecret: jwtSecret,
	}
}

// Proses login
func (s *authService) Login(ctx context.Context, input LoginInput) (*LoginResult, error) {
	// 1. Cari perusahaan berdasarkan email
	company, err := s.authRepo.FindByEmail(ctx, input.Email)
	if err != nil {
		return nil, errors.New("email atau password salah")
	}

	// 2. Cek password
	if !utils.CheckPassword(input.Password, company.PasswordHash) {
		return nil, errors.New("email atau password salah")
	}

	// 3. Generate JWT token
	token, err := utils.GenerateToken(company.ID, company.Name, company.Email, s.jwtSecret)
	if err != nil {
		return nil, fmt.Errorf("gagal generate token: %w", err)
	}

	return &LoginResult{
		Token:       token,
		CompanyName: company.Name,
		CompanyID:   company.ID,
	}, nil
}

// Proses register
func (s *authService) Register(ctx context.Context, input RegisterInput) error {
	// 1. Validasi input
	if input.CompanyName == "" || input.Email == "" || input.Password == "" {
		return errors.New("nama perusahaan, email, dan password wajib diisi")
	}

	if len(input.Password) < 6 {
		return errors.New("password minimal 6 karakter")
	}

	// 2. Cek apakah email sudah terdaftar
	exists, err := s.authRepo.EmailExists(ctx, input.Email)
	if err != nil {
		return fmt.Errorf("gagal cek email: %w", err)
	}
	if exists {
		return errors.New("email sudah terdaftar")
	}

	// 3. Hash password
	hashedPassword, err := utils.HashPassword(input.Password)
	if err != nil {
		return fmt.Errorf("gagal hash password: %w", err)
	}

	// 4. Generate nomor rekening
	accountNumber := utils.GenerateAccountNumber()

	// 5. Simpan ke database
	return s.authRepo.Create(ctx, input.CompanyName, input.Email, hashedPassword, input.Phone, accountNumber)
}
