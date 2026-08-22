package grpchandler

import (
	"context"

	"wholesales-app/backend/server/pb"
	"wholesales-app/backend/server/service"
)

// Struct yang mengimplementasikan AuthServiceServer dari proto
type AuthGRPCHandler struct {
	pb.UnimplementedAuthServiceServer // Wajib di-embed agar compile
	authService                       service.AuthService
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
