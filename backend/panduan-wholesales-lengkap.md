# Panduan Lengkap Backend Wholesales — Go gRPC + REST

> Semua file yang perlu dibuat ada di dokumen ini, berurutan dari atas ke bawah.

---

## Daftar Isi
1. [Struktur Folder](#1-struktur-folder)
2. [go.mod](#2-gomod)
3. [.env](#3-env)
4. [Proto Files](#4-proto-files)
5. [Generate Proto](#5-generate-proto)
6. [server/config/config.go](#6-serverconfigconfiggo)
7. [server/common/response.go](#7-servercommonresponsego)
8. [server/utils/jwt.go](#8-serverutilsjwtgo)
9. [server/utils/helper.go](#9-serverutilshelpergo)
10. [server/repository/auth_repository.go](#10-serverrepositoryauth_repositorygo)
11. [server/repository/company_repository.go](#11-serverrepositorycompany_repositorygo)
12. [server/repository/transfer_repository.go](#12-serverrepositorytransfer_repositorygo)
13. [server/service/auth_service.go](#13-serverserviceauth_servicego)
14. [server/service/company_service.go](#14-serverservicecompany_servicego)
15. [server/service/transfer_service.go](#15-serverservicetransfer_servicego)
16. [server/grpc/auth_handler.go](#16-servergrpcauth_handlergo)
17. [server/grpc/company_handler.go](#17-servergrpccompany_handlergo)
18. [server/grpc/transfer_handler.go](#18-servergrpctransfer_handlergo)
19. [server/api/auth_handler.go](#19-serverapiauth_handlergo)
20. [server/api/company_handler.go](#20-serverapicompany_handlergo)
21. [server/api/transfer_handler.go](#21-serverapitransfer_handlergo)
22. [server/main.go](#22-servermaingo)
23. [server/migrations/001_init.sql](#23-servermigrations001_initsql)
24. [docker-compose.yml](#24-docker-composeyml)
25. [Dockerfile](#25-dockerfile)
26. [generate.sh](#26-generatesh)
27. [Cara Menjalankan](#27-cara-menjalankan)

---

## 1. Struktur Folder

Buat semua folder ini terlebih dahulu:

```
backend/
├── proto/
├── server/
│   ├── api/
│   ├── common/
│   ├── config/
│   ├── grpc/
│   ├── migrations/
│   ├── pb/
│   ├── repository/
│   ├── service/
│   └── utils/
├── .env
├── docker-compose.yml
├── Dockerfile
├── generate.sh
├── go.mod
└── go.sum
```

Perintah untuk buat semua folder sekaligus (jalankan di dalam folder `backend/`):

```bash
mkdir -p proto server/api server/common server/config server/grpc server/migrations server/pb server/repository server/service server/utils
```

---

## 2. go.mod

File: `backend/go.mod`

```
module wholesales-app/backend

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/golang-jwt/jwt/v5 v5.2.0
    github.com/jmoiron/sqlx v1.3.5
    github.com/joho/godotenv v1.5.1
    github.com/lib/pq v1.10.9
    golang.org/x/crypto v0.17.0
    google.golang.org/grpc v1.60.0
    google.golang.org/protobuf v1.32.0
)
```

Setelah buat file ini, jalankan:

```bash
go mod tidy
```

---

## 3. .env

File: `backend/.env`

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=wholesales_db

GRPC_PORT=50051
REST_PORT=8080

JWT_SECRET=wholesales-super-secret-key-2024
```

---

## 4. Proto Files

### `proto/auth.proto`

```protobuf
syntax = "proto3";

package auth;
option go_package = "wholesales-app/backend/server/pb";

message LoginRequest {
  string email    = 1;
  string password = 2;
}

message LoginResponse {
  string token        = 1;
  string company_name = 2;
  int64  company_id   = 3;
  string message      = 4;
}

message RegisterRequest {
  string company_name = 1;
  string email        = 2;
  string password     = 3;
  string phone        = 4;
}

message RegisterResponse {
  string message = 1;
  bool   success = 2;
}

service AuthService {
  rpc Login    (LoginRequest)    returns (LoginResponse);
  rpc Register (RegisterRequest) returns (RegisterResponse);
}
```

### `proto/company.proto`

```protobuf
syntax = "proto3";

package company;
option go_package = "wholesales-app/backend/server/pb";

message Company {
  int64  id             = 1;
  string name           = 2;
  string email          = 3;
  string phone          = 4;
  double balance        = 5;
  string account_number = 6;
  string created_at     = 7;
}

message GetCompanyListRequest {
  int32 page  = 1;
  int32 limit = 2;
}

message GetCompanyListResponse {
  repeated Company companies = 1;
  int32            total     = 2;
}

message GetCompanyDetailRequest {
  int64 company_id = 1;
}

message TopUpRequest {
  int64  company_id = 1;
  double amount     = 2;
  string note       = 3;
}

message TopUpResponse {
  string message     = 1;
  double new_balance = 2;
}

message GetBalanceRequest {
  int64 company_id = 1;
}

message GetBalanceResponse {
  double balance        = 1;
  string account_number = 2;
}

service CompanyService {
  rpc GetCompanyList   (GetCompanyListRequest)   returns (GetCompanyListResponse);
  rpc GetCompanyDetail (GetCompanyDetailRequest) returns (Company);
  rpc TopUp            (TopUpRequest)            returns (TopUpResponse);
  rpc GetBalance       (GetBalanceRequest)       returns (GetBalanceResponse);
}
```

### `proto/transfer.proto`

```protobuf
syntax = "proto3";

package transfer;
option go_package = "wholesales-app/backend/server/pb";

enum TransferType {
  INTERNAL = 0;
  EXTERNAL = 1;
}

enum PaymentMethod {
  BI_FAST = 0;
  RTGS    = 1;
  SKN     = 2;
}

message Transfer {
  int64  id                = 1;
  int64  from_company_id   = 2;
  int64  to_company_id     = 3;
  string to_account_number = 4;
  string to_bank_name      = 5;
  double amount            = 6;
  double fee               = 7;
  string payment_method    = 8;
  string transfer_type     = 9;
  string status            = 10;
  string note              = 11;
  string created_at        = 12;
}

message DoTransferRequest {
  int64         from_company_id   = 1;
  string        to_account_number = 2;
  string        to_bank_name      = 3;
  double        amount            = 4;
  TransferType  transfer_type     = 5;
  PaymentMethod payment_method    = 6;
  string        note              = 7;
}

message DoTransferResponse {
  string message           = 1;
  bool   success           = 2;
  double remaining_balance = 3;
}

message GetHistoryRequest {
  int64 company_id = 1;
  int32 page       = 2;
  int32 limit      = 3;
}

message GetHistoryResponse {
  repeated Transfer transfers = 1;
  int32             total     = 2;
}

service TransferService {
  rpc DoTransfer (DoTransferRequest) returns (DoTransferResponse);
  rpc GetHistory (GetHistoryRequest) returns (GetHistoryResponse);
}
```

---

## 5. Generate Proto

### `generate.sh`

```bash
#!/bin/bash
echo "Generating protobuf files..."

protoc \
  --go_out=./server/pb \
  --go_opt=paths=source_relative \
  --go-grpc_out=./server/pb \
  --go-grpc_opt=paths=source_relative \
  -I ./proto \
  ./proto/*.proto

echo "Done! Cek folder server/pb/"
```

Jalankan:

```bash
chmod +x generate.sh
./generate.sh
```

Setelah berhasil, folder `server/pb/` akan berisi:
- `auth.pb.go`
- `auth_grpc.pb.go`
- `company.pb.go`
- `company_grpc.pb.go`
- `transfer.pb.go`
- `transfer_grpc.pb.go`

> ⚠️ Jangan edit file di dalam `server/pb/` secara manual!

---

## 6. server/config/config.go

```go
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
```

---

## 7. server/common/response.go

```go
package common

import "github.com/gin-gonic/gin"

// Struct standar untuk semua response REST API
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Response sukses
func Success(c *gin.Context, httpCode int, message string, data interface{}) {
	c.JSON(httpCode, Response{
		Code:    httpCode,
		Message: message,
		Data:    data,
	})
}

// Response error
func Error(c *gin.Context, httpCode int, message string) {
	c.JSON(httpCode, Response{
		Code:    httpCode,
		Message: message,
	})
}
```

---

## 8. server/utils/jwt.go

```go
package utils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Isi yang disimpan di dalam token JWT
type JWTClaims struct {
	CompanyID   int64  `json:"company_id"`
	CompanyName string `json:"company_name"`
	Email       string `json:"email"`
	jwt.RegisteredClaims
}

// Generate token JWT baru
func GenerateToken(companyID int64, companyName, email, secret string) (string, error) {
	claims := JWTClaims{
		CompanyID:   companyID,
		CompanyName: companyName,
		Email:       email,
		RegisteredClaims: jwt.RegisteredClaims{
			// Token berlaku 24 jam
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// Validasi dan parse token JWT
func ValidateToken(tokenString, secret string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(
		tokenString,
		&JWTClaims{},
		func(t *jwt.Token) (interface{}, error) {
			return []byte(secret), nil
		},
	)

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, errors.New("token tidak valid")
	}

	return claims, nil
}
```

---

## 9. server/utils/helper.go

```go
package utils

import (
	"golang.org/x/crypto/bcrypt"
)

// Hash password sebelum disimpan ke database
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// Cek apakah password cocok dengan hash-nya
func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// Generate nomor rekening random (10 digit)
func GenerateAccountNumber() string {
	// Dalam produksi, gunakan logika yang lebih proper
	// Ini contoh sederhana untuk pembelajaran
	return fmt.Sprintf("%010d", time.Now().UnixNano()%10000000000)
}
```

> ⚠️ Tambahkan import `fmt` dan `time` di atas file helper.go:
```go
import (
    "fmt"
    "time"
    "golang.org/x/crypto/bcrypt"
)
```

---

## 10. server/repository/auth_repository.go

```go
package repository

import (
	"context"
	"database/sql"
	"errors"

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
```

---

## 11. server/repository/company_repository.go

```go
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
```

---

## 12. server/repository/transfer_repository.go

```go
package repository

import (
	"context"

	"github.com/jmoiron/sqlx"
)

// Struct yang merepresentasikan tabel transfers
type Transfer struct {
	ID              int64   `db:"id"`
	FromCompanyID   int64   `db:"from_company_id"`
	ToCompanyID     int64   `db:"to_company_id"`
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
```

---

## 13. server/service/auth_service.go

```go
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
```

---

## 14. server/service/company_service.go

```go
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
```

---

## 15. server/service/transfer_service.go

```go
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
	// 1. Validasi minimal transfer
	if input.Amount < 10000 {
		return nil, errors.New("minimal transfer adalah Rp 10.000")
	}

	// 2. Ambil data perusahaan pengirim
	fromCompany, err := s.companyRepo.GetByID(ctx, input.FromCompanyID)
	if err != nil {
		return nil, errors.New("perusahaan pengirim tidak ditemukan")
	}

	// 3. Hitung biaya transfer
	// Transfer INTERNAL (sesama BRI) gratis, EXTERNAL kena biaya
	fee := 0.0
	if input.TransferType == "EXTERNAL" {
		fee = transferFees[input.PaymentMethod]
	}
	totalDeduct := input.Amount + fee

	// 4. Validasi saldo mencukupi
	if fromCompany.Balance < totalDeduct {
		return nil, fmt.Errorf(
			"saldo tidak mencukupi. Saldo: Rp %.0f, Dibutuhkan: Rp %.0f (termasuk biaya Rp %.0f)",
			fromCompany.Balance, totalDeduct, fee,
		)
	}

	// 5. Simpan record transfer ke database
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
```

---

## 16. server/grpc/auth_handler.go

```go
package grpchandler

import (
	"context"

	"wholesales-app/backend/server/pb"
	"wholesales-app/backend/server/service"
)

// Struct yang mengimplementasikan AuthServiceServer dari proto
type AuthGRPCHandler struct {
	pb.UnimplementedAuthServiceServer // Wajib di-embed agar compile
	authService service.AuthService
}

func NewAuthGRPCHandler(svc service.AuthService) *AuthGRPCHandler {
	return &AuthGRPCHandler{authService: svc}
}

// Implementasi fungsi Login dari proto/auth.proto
func (h *AuthGRPCHandler) Login(ctx context.Context, req *pb.LoginRequest) (*pb.LoginResponse, error) {
	result, err := h.authService.Login(ctx, service.LoginInput{
		Email:    req.Email,
		Password: req.Password,
	})

	if err != nil {
		return &pb.LoginResponse{
			Message: err.Error(),
		}, nil
	}

	return &pb.LoginResponse{
		Token:       result.Token,
		CompanyName: result.CompanyName,
		CompanyId:   result.CompanyID,
		Message:     "Login berhasil",
	}, nil
}

// Implementasi fungsi Register dari proto/auth.proto
func (h *AuthGRPCHandler) Register(ctx context.Context, req *pb.RegisterRequest) (*pb.RegisterResponse, error) {
	err := h.authService.Register(ctx, service.RegisterInput{
		CompanyName: req.CompanyName,
		Email:       req.Email,
		Password:    req.Password,
		Phone:       req.Phone,
	})

	if err != nil {
		return &pb.RegisterResponse{
			Success: false,
			Message: err.Error(),
		}, nil
	}

	return &pb.RegisterResponse{
		Success: true,
		Message: "Registrasi berhasil",
	}, nil
}
```

---

## 17. server/grpc/company_handler.go

```go
package grpchandler

import (
	"context"

	"wholesales-app/backend/server/pb"
	"wholesales-app/backend/server/service"
)

// Struct yang mengimplementasikan CompanyServiceServer dari proto
type CompanyGRPCHandler struct {
	pb.UnimplementedCompanyServiceServer // Wajib di-embed
	companyService service.CompanyService
}

func NewCompanyGRPCHandler(svc service.CompanyService) *CompanyGRPCHandler {
	return &CompanyGRPCHandler{companyService: svc}
}

// Ambil daftar semua perusahaan (untuk admin)
func (h *CompanyGRPCHandler) GetCompanyList(ctx context.Context, req *pb.GetCompanyListRequest) (*pb.GetCompanyListResponse, error) {
	companies, total, err := h.companyService.GetCompanyList(ctx, int(req.Page), int(req.Limit))
	if err != nil {
		return nil, err
	}

	// Convert dari struct repository ke struct proto
	var pbCompanies []*pb.Company
	for _, c := range companies {
		pbCompanies = append(pbCompanies, &pb.Company{
			Id:            c.ID,
			Name:          c.Name,
			Email:         c.Email,
			Phone:         c.Phone,
			Balance:       c.Balance,
			AccountNumber: c.AccountNumber,
			CreatedAt:     c.CreatedAt,
		})
	}

	return &pb.GetCompanyListResponse{
		Companies: pbCompanies,
		Total:     int32(total),
	}, nil
}

// Ambil detail satu perusahaan
func (h *CompanyGRPCHandler) GetCompanyDetail(ctx context.Context, req *pb.GetCompanyDetailRequest) (*pb.Company, error) {
	company, err := h.companyService.GetCompanyDetail(ctx, req.CompanyId)
	if err != nil {
		return nil, err
	}

	return &pb.Company{
		Id:            company.ID,
		Name:          company.Name,
		Email:         company.Email,
		Phone:         company.Phone,
		Balance:       company.Balance,
		AccountNumber: company.AccountNumber,
		CreatedAt:     company.CreatedAt,
	}, nil
}

// Top up saldo perusahaan
func (h *CompanyGRPCHandler) TopUp(ctx context.Context, req *pb.TopUpRequest) (*pb.TopUpResponse, error) {
	result, err := h.companyService.TopUp(ctx, service.TopUpInput{
		CompanyID: req.CompanyId,
		Amount:    req.Amount,
		Note:      req.Note,
	})

	if err != nil {
		return &pb.TopUpResponse{
			Message: err.Error(),
		}, nil
	}

	return &pb.TopUpResponse{
		Message:    result.Message,
		NewBalance: result.NewBalance,
	}, nil
}

// Ambil saldo perusahaan
func (h *CompanyGRPCHandler) GetBalance(ctx context.Context, req *pb.GetBalanceRequest) (*pb.GetBalanceResponse, error) {
	balance, accountNumber, err := h.companyService.GetBalance(ctx, req.CompanyId)
	if err != nil {
		return nil, err
	}

	return &pb.GetBalanceResponse{
		Balance:       balance,
		AccountNumber: accountNumber,
	}, nil
}
```

---

## 18. server/grpc/transfer_handler.go

```go
package grpchandler

import (
	"context"

	"wholesales-app/backend/server/pb"
	"wholesales-app/backend/server/service"
)

// Struct yang mengimplementasikan TransferServiceServer dari proto
type TransferGRPCHandler struct {
	pb.UnimplementedTransferServiceServer // Wajib di-embed
	transferService service.TransferService
}

func NewTransferGRPCHandler(svc service.TransferService) *TransferGRPCHandler {
	return &TransferGRPCHandler{transferService: svc}
}

// Proses transfer
func (h *TransferGRPCHandler) DoTransfer(ctx context.Context, req *pb.DoTransferRequest) (*pb.DoTransferResponse, error) {
	result, err := h.transferService.DoTransfer(ctx, service.TransferInput{
		FromCompanyID:   req.FromCompanyId,
		ToAccountNumber: req.ToAccountNumber,
		ToBankName:      req.ToBankName,
		Amount:          req.Amount,
		TransferType:    req.TransferType.String(),
		PaymentMethod:   req.PaymentMethod.String(),
		Note:            req.Note,
	})

	if err != nil {
		return &pb.DoTransferResponse{
			Success: false,
			Message: err.Error(),
		}, nil
	}

	return &pb.DoTransferResponse{
		Success:          result.Success,
		Message:          result.Message,
		RemainingBalance: result.RemainingBalance,
	}, nil
}

// Ambil history transfer
func (h *TransferGRPCHandler) GetHistory(ctx context.Context, req *pb.GetHistoryRequest) (*pb.GetHistoryResponse, error) {
	transfers, total, err := h.transferService.GetHistory(ctx, req.CompanyId, int(req.Page), int(req.Limit))
	if err != nil {
		return nil, err
	}

	var pbTransfers []*pb.Transfer
	for _, t := range transfers {
		pbTransfers = append(pbTransfers, &pb.Transfer{
			Id:              t.ID,
			FromCompanyId:   t.FromCompanyID,
			ToAccountNumber: t.ToAccountNumber,
			ToBankName:      t.ToBankName,
			Amount:          t.Amount,
			Fee:             t.Fee,
			PaymentMethod:   t.PaymentMethod,
			TransferType:    t.TransferType,
			Status:          t.Status,
			Note:            t.Note,
			CreatedAt:       t.CreatedAt,
		})
	}

	return &pb.GetHistoryResponse{
		Transfers: pbTransfers,
		Total:     int32(total),
	}, nil
}
```

---

## 19. server/api/auth_handler.go

```go
package apihandler

import (
	"net/http"

	"wholesales-app/backend/server/common"
	"wholesales-app/backend/server/pb"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
)

type AuthRESTHandler struct {
	grpcClient pb.AuthServiceClient
}

func NewAuthRESTHandler(conn *grpc.ClientConn) *AuthRESTHandler {
	return &AuthRESTHandler{
		grpcClient: pb.NewAuthServiceClient(conn),
	}
}

// POST /api/auth/login
func (h *AuthRESTHandler) Login(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Email dan password wajib diisi")
		return
	}

	result, err := h.grpcClient.Login(c.Request.Context(), &pb.LoginRequest{
		Email:    req.Email,
		Password: req.Password,
	})

	if err != nil {
		common.Error(c, http.StatusInternalServerError, "Terjadi kesalahan server")
		return
	}

	if result.Token == "" {
		common.Error(c, http.StatusUnauthorized, result.Message)
		return
	}

	common.Success(c, http.StatusOK, "Login berhasil", gin.H{
		"token":        result.Token,
		"company_name": result.CompanyName,
		"company_id":   result.CompanyId,
	})
}

// POST /api/auth/register
func (h *AuthRESTHandler) Register(c *gin.Context) {
	var req struct {
		CompanyName string `json:"company_name" binding:"required"`
		Email       string `json:"email" binding:"required,email"`
		Password    string `json:"password" binding:"required,min=6"`
		Phone       string `json:"phone"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Data tidak valid: "+err.Error())
		return
	}

	result, err := h.grpcClient.Register(c.Request.Context(), &pb.RegisterRequest{
		CompanyName: req.CompanyName,
		Email:       req.Email,
		Password:    req.Password,
		Phone:       req.Phone,
	})

	if err != nil {
		common.Error(c, http.StatusInternalServerError, "Terjadi kesalahan server")
		return
	}

	if !result.Success {
		common.Error(c, http.StatusBadRequest, result.Message)
		return
	}

	common.Success(c, http.StatusCreated, result.Message, nil)
}
```

---

## 20. server/api/company_handler.go

```go
package apihandler

import (
	"net/http"
	"strconv"

	"wholesales-app/backend/server/common"
	"wholesales-app/backend/server/pb"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
)

type CompanyRESTHandler struct {
	grpcClient pb.CompanyServiceClient
}

func NewCompanyRESTHandler(conn *grpc.ClientConn) *CompanyRESTHandler {
	return &CompanyRESTHandler{
		grpcClient: pb.NewCompanyServiceClient(conn),
	}
}

// GET /api/admin/companies?page=1&limit=10
func (h *CompanyRESTHandler) GetCompanyList(c *gin.Context) {
	page, _  := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	result, err := h.grpcClient.GetCompanyList(c.Request.Context(), &pb.GetCompanyListRequest{
		Page:  int32(page),
		Limit: int32(limit),
	})

	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Berhasil", gin.H{
		"companies": result.Companies,
		"total":     result.Total,
		"page":      page,
		"limit":     limit,
	})
}

// GET /api/company/balance?company_id=1
func (h *CompanyRESTHandler) GetBalance(c *gin.Context) {
	companyID, err := strconv.ParseInt(c.Query("company_id"), 10, 64)
	if err != nil {
		common.Error(c, http.StatusBadRequest, "company_id tidak valid")
		return
	}

	result, err := h.grpcClient.GetBalance(c.Request.Context(), &pb.GetBalanceRequest{
		CompanyId: companyID,
	})

	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Berhasil", gin.H{
		"balance":        result.Balance,
		"account_number": result.AccountNumber,
	})
}

// POST /api/company/topup
func (h *CompanyRESTHandler) TopUp(c *gin.Context) {
	var req struct {
		CompanyID int64   `json:"company_id" binding:"required"`
		Amount    float64 `json:"amount" binding:"required,min=10000"`
		Note      string  `json:"note"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Data tidak valid: "+err.Error())
		return
	}

	result, err := h.grpcClient.TopUp(c.Request.Context(), &pb.TopUpRequest{
		CompanyId: req.CompanyID,
		Amount:    req.Amount,
		Note:      req.Note,
	})

	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	if result.NewBalance == 0 && result.Message != "" {
		common.Error(c, http.StatusBadRequest, result.Message)
		return
	}

	common.Success(c, http.StatusOK, result.Message, gin.H{
		"new_balance": result.NewBalance,
	})
}
```

---

## 21. server/api/transfer_handler.go

```go
package apihandler

import (
	"net/http"
	"strconv"

	"wholesales-app/backend/server/common"
	"wholesales-app/backend/server/pb"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
)

type TransferRESTHandler struct {
	grpcClient pb.TransferServiceClient
}

func NewTransferRESTHandler(conn *grpc.ClientConn) *TransferRESTHandler {
	return &TransferRESTHandler{
		grpcClient: pb.NewTransferServiceClient(conn),
	}
}

// POST /api/transfer
func (h *TransferRESTHandler) DoTransfer(c *gin.Context) {
	var req struct {
		FromCompanyID   int64   `json:"from_company_id" binding:"required"`
		ToAccountNumber string  `json:"to_account_number" binding:"required"`
		ToBankName      string  `json:"to_bank_name"`
		Amount          float64 `json:"amount" binding:"required,min=10000"`
		TransferType    string  `json:"transfer_type" binding:"required"` // INTERNAL / EXTERNAL
		PaymentMethod   string  `json:"payment_method" binding:"required"` // BI_FAST, RTGS, SKN
		Note            string  `json:"note"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Data tidak valid: "+err.Error())
		return
	}

	// Konversi string ke enum proto
	transferType := pb.TransferType_INTERNAL
	if req.TransferType == "EXTERNAL" {
		transferType = pb.TransferType_EXTERNAL
	}

	paymentMethod := pb.PaymentMethod_BI_FAST
	switch req.PaymentMethod {
	case "RTGS":
		paymentMethod = pb.PaymentMethod_RTGS
	case "SKN":
		paymentMethod = pb.PaymentMethod_SKN
	}

	result, err := h.grpcClient.DoTransfer(c.Request.Context(), &pb.DoTransferRequest{
		FromCompanyId:   req.FromCompanyID,
		ToAccountNumber: req.ToAccountNumber,
		ToBankName:      req.ToBankName,
		Amount:          req.Amount,
		TransferType:    transferType,
		PaymentMethod:   paymentMethod,
		Note:            req.Note,
	})

	if err != nil {
		common.Error(c, http.StatusInternalServerError, "Terjadi kesalahan server")
		return
	}

	if !result.Success {
		common.Error(c, http.StatusBadRequest, result.Message)
		return
	}

	common.Success(c, http.StatusOK, result.Message, gin.H{
		"remaining_balance": result.RemainingBalance,
	})
}

// GET /api/transfer/history?company_id=1&page=1&limit=10
func (h *TransferRESTHandler) GetHistory(c *gin.Context) {
	companyID, err := strconv.ParseInt(c.Query("company_id"), 10, 64)
	if err != nil {
		common.Error(c, http.StatusBadRequest, "company_id tidak valid")
		return
	}

	page, _  := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	result, err := h.grpcClient.GetHistory(c.Request.Context(), &pb.GetHistoryRequest{
		CompanyId: companyID,
		Page:      int32(page),
		Limit:     int32(limit),
	})

	if err != nil {
		common.Error(c, http.StatusInternalServerError, err.Error())
		return
	}

	common.Success(c, http.StatusOK, "Berhasil", gin.H{
		"transfers": result.Transfers,
		"total":     result.Total,
		"page":      page,
		"limit":     limit,
	})
}
```

---

## 22. server/main.go

```go
package main

import (
	"fmt"
	"log"
	"net"
	"net/http"

	apihandler "wholesales-app/backend/server/api"
	"wholesales-app/backend/server/config"
	grpchandler "wholesales-app/backend/server/grpc"
	"wholesales-app/backend/server/pb"
	"wholesales-app/backend/server/repository"
	"wholesales-app/backend/server/service"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	// 1. Load konfigurasi dari .env
	cfg := config.Load()

	// 2. Connect ke database PostgreSQL
	db, err := cfg.ConnectDB()
	if err != nil {
		log.Fatalf("Gagal connect database: %v", err)
	}
	defer db.Close()
	log.Println("✅ Database connected")

	// =============================================
	// 3. Dependency Injection
	// Urutan: Repository → Service → Handler
	// =============================================

	// Layer Repository (akses database)
	authRepo     := repository.NewAuthRepository(db)
	companyRepo  := repository.NewCompanyRepository(db)
	transferRepo := repository.NewTransferRepository(db)

	// Layer Service (business logic)
	authService     := service.NewAuthService(authRepo, cfg.JWTSecret)
	companyService  := service.NewCompanyService(companyRepo)
	transferService := service.NewTransferService(transferRepo, companyRepo)

	// Layer gRPC Handler
	authGRPC     := grpchandler.NewAuthGRPCHandler(authService)
	companyGRPC  := grpchandler.NewCompanyGRPCHandler(companyService)
	transferGRPC := grpchandler.NewTransferGRPCHandler(transferService)

	// =============================================
	// 4. Jalankan gRPC Server
	// =============================================
	grpcServer := grpc.NewServer()
	pb.RegisterAuthServiceServer(grpcServer, authGRPC)
	pb.RegisterCompanyServiceServer(grpcServer, companyGRPC)
	pb.RegisterTransferServiceServer(grpcServer, transferGRPC)
	reflection.Register(grpcServer)

	grpcLis, err := net.Listen("tcp", ":"+cfg.GRPCPort)
	if err != nil {
		log.Fatalf("Gagal listen gRPC port: %v", err)
	}

	// Jalankan gRPC di goroutine (background) supaya tidak blocking
	go func() {
		log.Printf("🚀 gRPC Server berjalan di port %s", cfg.GRPCPort)
		if err := grpcServer.Serve(grpcLis); err != nil {
			log.Fatalf("gRPC server error: %v", err)
		}
	}()

	// =============================================
	// 5. Koneksi REST Gateway → gRPC Server
	// =============================================
	grpcAddr := fmt.Sprintf("localhost:%s", cfg.GRPCPort)
	grpcConn, err := grpc.Dial(grpcAddr, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Gagal connect ke gRPC: %v", err)
	}
	defer grpcConn.Close()

	// Layer REST Handler (menerima request dari Frontend)
	authREST     := apihandler.NewAuthRESTHandler(grpcConn)
	companyREST  := apihandler.NewCompanyRESTHandler(grpcConn)
	transferREST := apihandler.NewTransferRESTHandler(grpcConn)

	// =============================================
	// 6. Setup Routes REST API (Gin)
	// =============================================
	r := gin.Default()

	// Public — tidak perlu token
	r.POST("/api/auth/login",    authREST.Login)
	r.POST("/api/auth/register", authREST.Register)

	// Protected — perlu token JWT (middleware menyusul)
	api := r.Group("/api")
	{
		// Saldo & Top Up
		api.GET("/company/balance",  companyREST.GetBalance)
		api.POST("/company/topup",   companyREST.TopUp)

		// Transfer
		api.POST("/transfer",          transferREST.DoTransfer)
		api.GET("/transfer/history",   transferREST.GetHistory)

		// Admin
		api.GET("/admin/companies",    companyREST.GetCompanyList)
	}

	log.Printf("🌐 REST Server berjalan di port %s", cfg.RESTPort)
	if err := http.ListenAndServe(":"+cfg.RESTPort, r); err != nil {
		log.Fatalf("REST server error: %v", err)
	}
}
```

---

## 23. server/migrations/001_init.sql

```sql
-- Tabel utama: perusahaan (sekaligus tabel auth)
CREATE TABLE IF NOT EXISTS companies (
    id             BIGSERIAL    PRIMARY KEY,
    name           VARCHAR(255) NOT NULL,
    email          VARCHAR(255) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    phone          VARCHAR(20),
    balance        DECIMAL(15,2) NOT NULL DEFAULT 0,
    account_number VARCHAR(20) UNIQUE,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Tabel history transfer
CREATE TABLE IF NOT EXISTS transfers (
    id                BIGSERIAL    PRIMARY KEY,
    from_company_id   BIGINT       REFERENCES companies(id),
    to_company_id     BIGINT       REFERENCES companies(id),
    to_account_number VARCHAR(50)  NOT NULL,
    to_bank_name      VARCHAR(100),
    amount            DECIMAL(15,2) NOT NULL,
    fee               DECIMAL(15,2) NOT NULL DEFAULT 0,
    payment_method    VARCHAR(20)  NOT NULL, -- BI_FAST, RTGS, SKN
    transfer_type     VARCHAR(20)  NOT NULL, -- INTERNAL, EXTERNAL
    status            VARCHAR(20)  NOT NULL DEFAULT 'SUCCESS',
    note              TEXT,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index untuk mempercepat query history transfer
CREATE INDEX IF NOT EXISTS idx_transfers_from ON transfers(from_company_id);
CREATE INDEX IF NOT EXISTS idx_transfers_to   ON transfers(to_company_id);

-- Data dummy untuk testing
INSERT INTO companies (name, email, password_hash, phone, balance, account_number)
VALUES
    ('PT Maju Bersama',  'maju@example.com',      '$2a$10$dummy', '081234567890', 50000000, '1234567890'),
    ('PT Sejahtera Jaya','sejahtera@example.com',  '$2a$10$dummy', '089876543210', 25000000, '0987654321'),
    ('PT Admin Bank',    'admin@wholesales.com',   '$2a$10$dummy', '021-5551234',  0,        '0000000001')
ON CONFLICT DO NOTHING;
```

---

## 24. docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: wholesales_db
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: wholesales_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./server/migrations:/docker-entrypoint-initdb.d

  redis:
    image: redis:7-alpine
    container_name: wholesales_redis
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

---

## 25. Dockerfile

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o main ./server/main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
COPY .env .
EXPOSE 8080 50051
CMD ["./main"]
```

---

## 26. generate.sh

```bash
#!/bin/bash
echo "🔄 Generating protobuf files..."

protoc \
  --go_out=./server/pb \
  --go_opt=paths=source_relative \
  --go-grpc_out=./server/pb \
  --go-grpc_opt=paths=source_relative \
  -I ./proto \
  ./proto/*.proto

echo "✅ Done! File tersimpan di server/pb/"
```

---

## 27. Cara Menjalankan

### Urutan yang Benar

```bash
# Masuk ke folder backend
cd wholesales-app/backend

# Step 1: Jalankan database dulu
docker-compose up postgres -d

# Step 2: Tunggu 5 detik, lalu generate proto
./generate.sh

# Step 3: Download semua dependency
go mod tidy

# Step 4: Jalankan server
go run server/main.go
```

### Jika Berhasil, Output-nya:

```
✅ Database connected
🚀 gRPC Server berjalan di port 50051
🌐 REST Server berjalan di port 8080
```

### Test API

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"company_name":"PT Test","email":"test@test.com","password":"123456","phone":"081234"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123456"}'

# Cek saldo
curl "http://localhost:8080/api/company/balance?company_id=1"

# Transfer
curl -X POST http://localhost:8080/api/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "from_company_id": 1,
    "to_account_number": "0987654321",
    "to_bank_name": "BRI",
    "amount": 500000,
    "transfer_type": "INTERNAL",
    "payment_method": "BI_FAST",
    "note": "Test transfer"
  }'

# History transfer
curl "http://localhost:8080/api/transfer/history?company_id=1&page=1&limit=10"
```

---

## Checklist File

Sebelum `go run`, pastikan semua file ini sudah ada:

- [ ] `proto/auth.proto`
- [ ] `proto/company.proto`
- [ ] `proto/transfer.proto`
- [ ] `server/pb/` (hasil generate, minimal 6 file .go)
- [ ] `server/config/config.go`
- [ ] `server/common/response.go`
- [ ] `server/utils/jwt.go`
- [ ] `server/utils/helper.go`
- [ ] `server/repository/auth_repository.go`
- [ ] `server/repository/company_repository.go`
- [ ] `server/repository/transfer_repository.go`
- [ ] `server/service/auth_service.go`
- [ ] `server/service/company_service.go`
- [ ] `server/service/transfer_service.go`
- [ ] `server/grpc/auth_handler.go`
- [ ] `server/grpc/company_handler.go`
- [ ] `server/grpc/transfer_handler.go`
- [ ] `server/api/auth_handler.go`
- [ ] `server/api/company_handler.go`
- [ ] `server/api/transfer_handler.go`
- [ ] `server/main.go`
- [ ] `server/migrations/001_init.sql`
- [ ] `.env`
- [ ] `go.mod`
- [ ] `docker-compose.yml`

## 28. Install Air untuk otomatis menjalankan project reload jika terjadi perubahan code 

go install github.com/air-verse/air@latest
air -v

Buat file .air.toml
root = "."
tmp_dir = "tmp"

[build]
cmd = "go run server/main.go"
include_ext = ["go"]
exclude_dir = ["vendor", "pb"]

#Jalankan air di terminal 
air 
