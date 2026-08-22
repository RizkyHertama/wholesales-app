#!/bin/bash
echo "🔄 Generating protobuf files..."

protoc \
  --go_out=./server/pb \
  --go_opt=paths=source_relative \
  --go-grpc_out=./server/pb \
  --go-grpc_opt=paths=source_relative \
  -I ./proto \
  ./proto/*.proto

echo "✅ Done! File tersimpan di server/pb/"