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
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
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

// GET /api/company/balance
func (h *CompanyRESTHandler) GetBalance(c *gin.Context) {
	companyID, ok := middleware.GetCompanyID(c)
	if !ok {
		common.Error(c, http.StatusUnauthorized, "Token tidak valid")
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
	companyID, ok := middleware.GetCompanyID(c)
	if !ok {
		common.Error(c, http.StatusUnauthorized, "Token tidak valid")
		return
	}

	var req struct {
		Amount float64 `json:"amount" binding:"required,min=10000"`
		Note   string  `json:"note"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		common.Error(c, http.StatusBadRequest, "Data tidak valid: "+err.Error())
		return
	}

	result, err := h.grpcClient.TopUp(c.Request.Context(), &pb.TopUpRequest{
		CompanyId: companyID,
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
