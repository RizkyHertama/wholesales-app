package main

import (
	"fmt"
	"log"
	"net"
	"net/http"

	apihandler "wholesales-app/backend/server/api"
	"wholesales-app/backend/server/config"
	grpchandler "wholesales-app/backend/server/grpc"
	"wholesales-app/backend/server/pb"
	"wholesales-app/backend/server/repository"
	"wholesales-app/backend/server/service"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	// 1. Load konfigurasi dari .env
	cfg := config.Load()

	// 2. Connect ke database PostgreSQL
	db, err := cfg.ConnectDB()
	if err != nil {
		log.Fatalf("Gagal connect database: %v", err)
	}
	defer db.Close()
	log.Println("✅ Database connected")

	// =============================================
	// 3. Dependency Injection
	// Urutan: Repository → Service → Handler
	// =============================================

	// Layer Repository (akses database)
	authRepo := repository.NewAuthRepository(db)
	companyRepo := repository.NewCompanyRepository(db)
	transferRepo := repository.NewTransferRepository(db)

	// Layer Service (business logic)
	authService := service.NewAuthService(authRepo, cfg.JWTSecret)
	companyService := service.NewCompanyService(companyRepo)
	transferService := service.NewTransferService(transferRepo, companyRepo)

	// Layer gRPC Handler
	authGRPC := grpchandler.NewAuthGRPCHandler(authService)
	companyGRPC := grpchandler.NewCompanyGRPCHandler(companyService)
	transferGRPC := grpchandler.NewTransferGRPCHandler(transferService)

	// =============================================
	// 4. Jalankan gRPC Server
	// =============================================
	grpcServer := grpc.NewServer()
	pb.RegisterAuthServiceServer(grpcServer, authGRPC)
	pb.RegisterCompanyServiceServer(grpcServer, companyGRPC)
	pb.RegisterTransferServiceServer(grpcServer, transferGRPC)
	reflection.Register(grpcServer)

	grpcLis, err := net.Listen("tcp", ":"+cfg.GRPCPort)
	if err != nil {
		log.Fatalf("Gagal listen gRPC port: %v", err)
	}

	// Jalankan gRPC di goroutine (background) supaya tidak blocking
	go func() {
		log.Printf("🚀 gRPC Server berjalan di port %s", cfg.GRPCPort)
		if err := grpcServer.Serve(grpcLis); err != nil {
			log.Fatalf("gRPC server error: %v", err)
		}
	}()

	// =============================================
	// 5. Koneksi REST Gateway → gRPC Server
	// =============================================
	grpcAddr := fmt.Sprintf("localhost:%s", cfg.GRPCPort)
	grpcConn, err := grpc.Dial(grpcAddr, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Gagal connect ke gRPC: %v", err)
	}
	defer grpcConn.Close()

	// Layer REST Handler (menerima request dari Frontend)
	authREST := apihandler.NewAuthRESTHandler(grpcConn)
	companyREST := apihandler.NewCompanyRESTHandler(grpcConn)
	transferREST := apihandler.NewTransferRESTHandler(grpcConn)

	// =============================================
	// 6. Setup Routes REST API (Gin)
	// =============================================
	r := gin.Default()

	// Public — tidak perlu token
	r.POST("/api/auth/login", authREST.Login)
	r.POST("/api/auth/register", authREST.Register)

	// Protected — perlu token JWT (middleware menyusul)
	api := r.Group("/api")
	{
		// Saldo & Top Up
		api.GET("/company/balance", companyREST.GetBalance)
		api.POST("/company/topup", companyREST.TopUp)

		// Transfer
		api.POST("/transfer", transferREST.DoTransfer)
		api.GET("/transfer/history", transferREST.GetHistory)

		// Admin
		api.GET("/admin/companies", companyREST.GetCompanyList)
	}

	log.Printf("🌐 REST Server berjalan di port %s", cfg.RESTPort)
	if err := http.ListenAndServe(":"+cfg.RESTPort, r); err != nil {
		log.Fatalf("REST server error: %v", err)
	}
}
