package common

import (
	"context"
	"log"
	"time"
)

// LoggingInterceptor contoh interceptor sederhana
func LoggingInterceptor(ctx context.Context, method string, req interface{}, handler func(ctx context.Context, req interface{}) (interface{}, error)) (interface{}, error) {
	start := time.Now()
	res, err := handler(ctx, req)
	duration := time.Since(start)

	if err != nil {
		log.Printf("❌ Method=%s Error=%v Duration=%s", method, err, duration)
	} else {
		log.Printf("✅ Method=%s Success Duration=%s", method, duration)
	}

	return res, err
}
