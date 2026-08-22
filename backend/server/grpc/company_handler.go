package grpchandler

import (
	"context"

	"wholesales-app/backend/server/pb"
	"wholesales-app/backend/server/service"
)

// Struct yang mengimplementasikan CompanyServiceServer dari proto
type CompanyGRPCHandler struct {
	pb.UnimplementedCompanyServiceServer // Wajib di-embed
	companyService                       service.CompanyService
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
