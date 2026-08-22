package common

import "github.com/gin-gonic/gin"

// Struct standar untuk semua response REST API
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Response sukses
func Success(c *gin.Context, httpCode int, message string, data interface{}) {
	c.JSON(httpCode, Response{
		Code:    httpCode,
		Message: message,
		Data:    data,
	})
}

// Response error
func Error(c *gin.Context, httpCode int, message string) {
	c.JSON(httpCode, Response{
		Code:    httpCode,
		Message: message,
	})
}
