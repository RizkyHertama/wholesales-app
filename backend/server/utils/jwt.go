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
