package grpchandler

import (
	"context"

	"wholesales-app/backend/server/pb"
	"wholesales-app/backend/server/service"
)

// Struct yang mengimplementasikan TransferServiceServer dari proto
type TransferGRPCHandler struct {
	pb.UnimplementedTransferServiceServer // Wajib di-embed
	transferService                       service.TransferService
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
