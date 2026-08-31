package middleware

import (
	"net/http"
	"strings"

	"wholesales-app/backend/server/common"
	"wholesales-app/backend/server/utils"

	"github.com/gin-gonic/gin"
)

// AuthMiddleware memvalidasi header "Authorization: Bearer <token>".
// Request tanpa token valid akan ditolak sebelum masuk ke handler.
func AuthMiddleware(jwtSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			common.Error(c, http.StatusUnauthorized, "Token tidak ditemukan")
			c.Abort()
			return
		}

		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") || parts[1] == "" {
			common.Error(c, http.StatusUnauthorized, "Format token harus Bearer <token>")
			c.Abort()
			return
		}

		claims, err := utils.ValidateToken(parts[1], jwtSecret)
		if err != nil {
			common.Error(c, http.StatusUnauthorized, "Token tidak valid atau kadaluarsa")
			c.Abort()
			return
		}

		// Simpan klaim di context supaya bisa dipakai handler berikutnya
		c.Set("company_id", claims.CompanyID)
		c.Set("company_name", claims.CompanyName)
		c.Set("email", claims.Email)

		c.Next()
	}
}

// GetCompanyID mengambil company_id milik pemilik token dari context.
// Dipakai handler supaya company_id tidak pernah diambil dari input user.
func GetCompanyID(c *gin.Context) (int64, bool) {
	val, exists := c.Get("company_id")
	if !exists {
		return 0, false
	}
	companyID, ok := val.(int64)
	return companyID, ok
}
