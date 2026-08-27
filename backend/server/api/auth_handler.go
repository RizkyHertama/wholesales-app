package apihandler

import (
	"net/http"
	"strings"

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
		common.Error(c, http.StatusBadRequest, "Request tidak valid")
		return
	}

	// Validasi email dan password wajib diisi
	if req.Email == "" || req.Password == "" {
		common.Error(c, http.StatusBadRequest, "Email dan password wajib diisi")
		return
	}

	// Validasi format email
	if !strings.Contains(req.Email, "@") {
		common.Error(c, http.StatusBadRequest, "Email tidak valid")
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
