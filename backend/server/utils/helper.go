package utils

import (
	"fmt"
	"time"

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
