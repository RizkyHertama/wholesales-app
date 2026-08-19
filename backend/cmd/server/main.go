package main

import (
    "database/sql"
    "log"
    "net"
    "os"

    "github.com/yourusername/wholesales-app/backend/internal/common"
    "github.com/yourusername/wholesales-app/backend/internal/transfer"
    pb "github.com/yourusername/wholesales-app/backend/proto"

    "google.golang.org/grpc"
    _ "github.com/go-sql-driver/mysql"
)

func main() {
    // env or defaults
    dbUser := os.Getenv("DB_USER")
    if dbUser == "" { dbUser = "root" }
    dbPass := os.Getenv("DB_PASS")
    dbHost := os.Getenv("DB_HOST")
    if dbHost == "" { dbHost = "127.0.0.1:3306" }
    dbName := os.Getenv("DB_NAME")
    if dbName == "" { dbName = "wholesales_db" }

    db, err := common.NewDB(dbUser, dbPass, dbHost, dbName)
    if err != nil {
        log.Fatalf("db connect: %v", err)
    }
    defer db.Close()

    lis, err := net.Listen("tcp", ":50051")
    if err != nil {
        log.Fatalf("listen: %v", err)
    }

    grpcServer := grpc.NewServer(
        grpc.UnaryInterceptor(common.UnaryAuthInterceptor("secret")), // simple demo interceptor
    )

    pb.RegisterTransferServiceServer(grpcServer, transfer.NewServer(db))

    log.Println("gRPC server running on :50051")
    if err := grpcServer.Serve(lis); err != nil {
        log.Fatalf("serve: %v", err)
    }
}
