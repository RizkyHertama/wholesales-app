package common

import (
	"context"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

// Very small demo interceptor: accepts requests with "authorization: Bearer <token>".
// In production validate JWT and set claims in context.
func UnaryAuthInterceptor(secret string) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
		md, _ := metadata.FromIncomingContext(ctx)
		auth := ""
		if v := md["authorization"]; len(v) > 0 {
			auth = v[0]
		}
		if auth != "" && strings.HasPrefix(auth, "Bearer ") {
			// TODO: validate token and attach claims to ctx
			return handler(ctx, req)
		}
		// allow unauthenticated for demo endpoints like Register/Login
		return handler(ctx, req)
	}
}
