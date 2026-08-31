package apihandler

import (
	"net/http"
	"strconv"

	"wholesales-app/backend/server/common"
	"wholesales-app/backend/server/middleware"
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
	companyID, ok := middleware.GetCompanyID(c)
	if !ok {
		common.Error(c, http.StatusUnauthorized, "Token tidak valid")
		return
	}

	var req struct {
		ToAccountNumber string  `json:"to_account_number" binding:"required"`
		ToBankName      string  `json:"to_bank_name"`
		Amount          float64 `json:"amount" binding:"required,min=10000"`
		TransferType    string  `json:"transfer_type" binding:"required"`  // INTERNAL / EXTERNAL
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
		FromCompanyId:   companyID,
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

// GET /api/transfer/history?page=1&limit=10
func (h *TransferRESTHandler) GetHistory(c *gin.Context) {
	companyID, ok := middleware.GetCompanyID(c)
	if !ok {
		common.Error(c, http.StatusUnauthorized, "Token tidak valid")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
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
