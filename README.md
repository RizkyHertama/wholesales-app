Bisa. Dari struktur folder yang terlihat di screenshot, arsitekturnya kira-kira seperti ini:

```text
backend/
├── proto/
├── server/
│   ├── api/
│   │   ├── auth_handler.go
│   │   ├── company_handler.go
│   │   └── transfer_handler.go
│   ├── common/
│   │   └── response.go
│   ├── config/
│   │   └── config.go
│   ├── grpc/
│   │   ├── auth_handler.go
│   │   ├── company_handler.go
│   │   └── transfer_handler.go
│   ├── migrations/
│   │   └── 001_init.sql
│   ├── repository/
│   │   ├── auth_repository.go
│   │   ├── company_repository.go
│   │   └── transfer_repository.go
│   ├── service/
│   │   ├── auth_service.go
│   │   ├── company_service.go
│   │   └── transfer_service.go
│   ├── utils/
│   │   ├── helper.go
│   │   └── jwt.go
│   └── main.go
├── .env
├── docker-compose.yaml
├── Dockerfile
├── generate.sh
├── go.mod
└── go.sum
```

Untuk README, saya sarankan penjelasannya dibuat sedikit lebih sistematis daripada contohmu, terutama karena project ini punya **dua jalur API: REST dan gRPC**.

Berikut versi yang bisa langsung kamu **copy-paste ke `README.md`**:

## Struktur Folder & Fungsinya

Backend menggunakan **Golang** dengan arsitektur yang memisahkan antara API/Handler, Service, Repository, dan Database.

Secara sederhana, alur request adalah:

```text
Client
  │
  ├── REST API ──> server/api
  │                    │
  │                    ▼
  │                 service
  │                    │
  │                    ▼
  │                repository
  │                    │
  │                    ▼
  │                 Database
  │
  └── gRPC ─────> server/grpc
                       │
                       ▼
                    service
                       │
                       ▼
                   repository
                       │
                       ▼
                    Database
```

---

## Struktur Utama

```text
backend/
├── proto/
├── server/
│   ├── api/
│   ├── common/
│   ├── config/
│   ├── grpc/
│   ├── migrations/
│   ├── repository/
│   ├── service/
│   ├── utils/
│   └── main.go
├── .env
├── docker-compose.yaml
├── Dockerfile
├── generate.sh
├── go.mod
└── go.sum
```

---

## 1. `proto/`

Tempat menyimpan file **`.proto`** yang digunakan sebagai kontrak komunikasi **gRPC**.

Contohnya:

```text
proto/
├── auth.proto
├── company.proto
└── transfer.proto
```

File `.proto` mendefinisikan:

* Request
* Response
* Service
* RPC method
* Field yang dikirim dan diterima

Contoh:

```proto
service AuthService {
    rpc Login(LoginRequest) returns (LoginResponse);
}
```

Dari file `.proto` kemudian dilakukan proses generate untuk menghasilkan kode Go seperti:

```text
.pb.go
_grpc.pb.go
```

### Jika ada perubahan

Kalau ada perubahan kontrak API gRPC, misalnya menambahkan field:

```proto
message LoginResponse {
    string token = 1;
    int64 expires_at = 2;
    string username = 3;
}
```

maka file hasil generate perlu dibuat ulang menggunakan script/proses generate yang digunakan project.

> **Catatan:** perubahan database tidak selalu berarti `.proto` harus berubah. `.proto` hanya perlu berubah jika perubahan tersebut memang memengaruhi data yang dikirim/diterima melalui gRPC.

---

## 2. `server/api/`

Berisi **REST API Handler**.

Folder ini merupakan bagian yang menerima request HTTP dari client, kemudian meneruskannya ke service.

Contoh:

```text
api/
├── auth_handler.go
├── company_handler.go
└── transfer_handler.go
```

### `auth_handler.go`

Menangani endpoint REST yang berhubungan dengan authentication.

Contohnya:

```text
POST /login
```

Handler menerima request HTTP, membaca data request, kemudian memanggil:

```text
auth_service
```

### `company_handler.go`

Menangani endpoint REST yang berhubungan dengan company.

Contohnya dapat berupa:

```text
GET    /companies
POST   /companies
GET    /companies/:id
```

### `transfer_handler.go`

Menangani endpoint REST yang berhubungan dengan transfer.

Contohnya:

```text
POST /transfers
GET  /transfers
```

### Jika ada perubahan

Jika ada perubahan pada endpoint REST, request/response JSON, HTTP method, atau routing, maka handler biasanya perlu diubah.

---

## 3. `server/grpc/`

Berisi **gRPC Handler / Server Implementation**.

Folder ini mengimplementasikan service yang sudah didefinisikan di file `.proto`.

Contoh:

```text
grpc/
├── auth_handler.go
├── company_handler.go
└── transfer_handler.go
```

### `auth_handler.go`

Implementasi gRPC untuk authentication.

Misalnya `.proto` memiliki:

```proto
rpc Login(LoginRequest) returns (LoginResponse);
```

Maka handler gRPC akan memiliki method untuk menjalankan proses `Login`.

### `company_handler.go`

Implementasi gRPC untuk operasi company.

### `transfer_handler.go`

Implementasi gRPC untuk operasi transfer.

### Alur gRPC

```text
gRPC Client
     │
     ▼
grpc/auth_handler.go
     │
     ▼
auth_service.go
     │
     ▼
auth_repository.go
     │
     ▼
Database
```

### Jika ada perubahan

Jika `.proto` berubah, misalnya:

```proto
message TransferRequest {
    string from_account = 1;
    string to_account = 2;
    double amount = 3;
}
```

menjadi:

```proto
message TransferRequest {
    string from_account = 1;
    string to_account = 2;
    double amount = 3;
    string description = 4;
}
```

maka handler gRPC dan bagian lain yang menggunakan field tersebut kemungkinan perlu disesuaikan.

---

## 4. `server/service/`

Berisi **business logic / aturan bisnis aplikasi**.

Contoh:

```text
service/
├── auth_service.go
├── company_service.go
└── transfer_service.go
```

Service merupakan bagian yang menentukan **apa yang harus dilakukan aplikasi**.

### `auth_service.go`

Menangani business logic authentication.

Contohnya:

```text
Login
  ↓
Cari user
  ↓
Validasi password
  ↓
Generate JWT
  ↓
Return token
```

### `company_service.go`

Menangani business logic company.

Contohnya:

```text
Create Company
  ↓
Validasi data
  ↓
Cek email/account
  ↓
Simpan melalui repository
```

### `transfer_service.go`

Menangani business logic transfer.

Contohnya:

```text
Transfer
  ↓
Validasi account
  ↓
Cek saldo
  ↓
Validasi amount
  ↓
Proses transfer
  ↓
Simpan history transfer
```

### Jika ada perubahan

Kalau aturan bisnis berubah, biasanya perubahan dilakukan di `service`.

Contohnya:

```text
Saldo tidak boleh kurang dari 0
```

kemudian bisnis meminta:

```text
Transfer harus memiliki minimum amount Rp10.000
```

maka validasi tersebut dapat ditambahkan di `transfer_service.go`.

---

## 5. `server/repository/`

Berisi logic untuk **mengakses database**, terutama query SQL.

Contoh:

```text
repository/
├── auth_repository.go
├── company_repository.go
└── transfer_repository.go
```

Repository bertanggung jawab terhadap komunikasi dengan database.

### `auth_repository.go`

Query yang berkaitan dengan authentication/user.

Contohnya:

```sql
SELECT ...
FROM companies
WHERE email = ?
```

### `company_repository.go`

Query yang berkaitan dengan company.

Contohnya:

```text
Create
Read
Update
Delete
```

### `transfer_repository.go`

Query yang berkaitan dengan transaksi transfer.

Contohnya:

```text
Create Transfer
Get Transfer History
Get Transfer By ID
```

### Jika ada perubahan

Kalau ada perubahan struktur database, repository biasanya perlu diperiksa.

Misalnya sebelumnya:

```text
companies
- id
- name
- email
- balance
```

kemudian ditambahkan:

```text
status
```

maka query yang membutuhkan `status` harus disesuaikan.

---

## 6. `server/migrations/`

Berisi file SQL untuk **membuat atau mengubah struktur database**.

Contohnya:

```text
migrations/
└── 001_init.sql
```

File migration biasanya berisi:

* `CREATE TABLE`
* `ALTER TABLE`
* `CREATE INDEX`
* `INSERT` data awal/dummy

Contoh:

```sql
CREATE TABLE IF NOT EXISTS companies (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0
);
```

### Jika ada perubahan

Jika struktur database berubah, migration perlu dibuat atau diperbarui sesuai mekanisme migration project.

Contoh:

```text
Tambah kolom status
        ↓
Migration
        ↓
Database berubah
        ↓
Repository disesuaikan
        ↓
Service/handler disesuaikan jika diperlukan
```

> **Catatan:** migration bertanggung jawab terhadap struktur/data database, bukan business logic.

---

## 7. `server/config/`

Berisi konfigurasi aplikasi.

Contohnya:

```text
config/
└── config.go
```

Biasanya digunakan untuk membaca konfigurasi seperti:

```text
Database Host
Database Port
Database User
Database Password
JWT Secret
Server Port
Environment
```

Sebagian konfigurasi dapat berasal dari file:

```text
.env
```

### Jika ada perubahan

Biasanya berubah ketika:

* Database berubah
* Port server berubah
* Environment berubah
* JWT configuration berubah
* Configuration baru ditambahkan

---

## 8. `server/common/`

Berisi komponen umum yang digunakan oleh beberapa bagian aplikasi.

Contohnya:

```text
common/
└── response.go
```

`response.go` dapat digunakan untuk membuat format response yang konsisten.

Contoh:

```json
{
    "success": true,
    "message": "Success",
    "data": {}
}
```

Tujuannya agar response dari berbagai endpoint memiliki struktur yang konsisten.

---

## 9. `server/utils/`

Berisi helper/function yang bersifat umum dan dapat digunakan di berbagai bagian aplikasi.

Contohnya:

```text
utils/
├── helper.go
└── jwt.go
```

### `helper.go`

Berisi fungsi bantuan umum yang digunakan oleh aplikasi.

Contohnya dapat berupa:

```text
String helper
Validation helper
Conversion helper
Error helper
```

### `jwt.go`

Berhubungan dengan **JWT (JSON Web Token)**.

Biasanya digunakan untuk:

```text
Generate Token
Validate Token
Extract User Information
```

Contoh alurnya:

```text
Login berhasil
     ↓
Generate JWT
     ↓
Client menerima token
     ↓
Client mengirim token
     ↓
JWT validation
     ↓
Request diteruskan
```

---

## 10. `server/main.go`

Merupakan **entry point aplikasi Go**.

Saat menjalankan:

```bash
go run .
```

atau menjalankan binary hasil build, program akan mulai dari `main.go`.

Biasanya `main.go` bertanggung jawab untuk:

1. Membaca configuration
2. Membuka koneksi database
3. Menyiapkan repository
4. Menyiapkan service
5. Membuat/register REST handler
6. Membuat/register gRPC handler
7. Menjalankan server

Secara sederhana:

```text
main.go
   │
   ├── Config
   │
   ├── Database
   │
   ├── Repository
   │
   ├── Service
   │
   ├── REST API Handler
   │
   └── gRPC Handler
           │
           ▼
        Server
```

---

## 11. `.env`

Berisi environment variable yang digunakan aplikasi.

Contohnya:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=app
DB_PASSWORD=pass
DB_NAME=wholesales_db
```

Digunakan untuk menyimpan konfigurasi yang sebaiknya tidak ditulis langsung di source code.

> **Catatan:** `.env` yang berisi password/secret sebaiknya tidak di-commit ke Git repository. Gunakan `.gitignore`.

---

## 12. `docker-compose.yaml`

Digunakan untuk menjalankan beberapa service menggunakan Docker Compose.

Pada project ini salah satunya digunakan untuk menjalankan PostgreSQL.

Contoh konsep:

```text
Docker Compose
      │
      ▼
PostgreSQL Container
      │
      ▼
wholesales_db
```

Keuntungannya adalah environment database dapat dibuat lebih konsisten tanpa perlu install PostgreSQL secara manual di komputer.

---

## 13. `Dockerfile`

Berisi instruksi untuk membuat **Docker image** aplikasi.

Biasanya prosesnya:

```text
Source Code
    ↓
Dockerfile
    ↓
Docker Image
    ↓
Docker Container
    ↓
Go Application
```

Digunakan ketika aplikasi ingin dijalankan di environment/container yang terisolasi.

---

## 14. `generate.sh`

Script untuk membantu proses **generate kode**, terutama dari file `.proto` menjadi kode Go untuk gRPC.

Contoh konsep:

```text
.proto
   ↓
generate.sh
   ↓
.pb.go
_grpc.pb.go
```

Jika terdapat perubahan pada `.proto`, script ini biasanya perlu dijalankan kembali agar generated code sesuai dengan kontrak terbaru.

---

## 15. `go.mod`

Berisi informasi module dan dependency project Go.

Contohnya:

```text
module github.com/RizkyHertama/wholesales-app.git
```

`go.mod` digunakan Go untuk mengetahui:

* Nama module
* Versi Go
* Dependency yang digunakan
* Versi dependency

---

## 16. `go.sum`

Berisi checksum/version information dari dependency Go.

File ini membantu Go memastikan dependency yang digunakan sesuai dengan versi dan checksum yang tercatat.

Biasanya **tidak diedit secara manual**.

---

# Perbedaan `api/` dan `grpc/`

Project ini memiliki dua cara komunikasi:

| Folder         | Teknologi        | Komunikasi                |
| -------------- | ---------------- | ------------------------- |
| `server/api/`  | REST API         | HTTP/JSON                 |
| `server/grpc/` | gRPC             | HTTP/2 + Protocol Buffers |
| `proto/`       | Protocol Buffers | Kontrak untuk gRPC        |

Contoh REST:

```text
Client
  │
  │ HTTP + JSON
  ▼
server/api/
  │
  ▼
service/
  │
  ▼
repository/
  │
  ▼
Database
```

Contoh gRPC:

```text
Client
  │
  │ gRPC + Protobuf
  ▼
server/grpc/
  │
  ▼
service/
  │
  ▼
repository/
  │
  ▼
Database
```

Yang penting, **REST dan gRPC dapat menggunakan service dan repository yang sama**.

Jadi business logic tidak perlu ditulis dua kali.

---

# Hubungan Antar Folder

Secara keseluruhan:

```text
                 ┌──────────────┐
                 │    Client    │
                 └──────┬───────┘
                        │
              ┌─────────┴─────────┐
              │                   │
              ▼                   ▼
        ┌───────────┐       ┌───────────┐
        │ REST API  │       │   gRPC    │
        │ server/api│       │server/grpc│
        └─────┬─────┘       └─────┬─────┘
              │                   │
              └─────────┬─────────┘
                        ▼
                ┌──────────────┐
                │   Service    │
                │ Business     │
                │ Logic        │
                └──────┬───────┘
                       ▼
                ┌──────────────┐
                │ Repository   │
                │ SQL / DB     │
                └──────┬───────┘
                       ▼
                ┌──────────────┐
                │  PostgreSQL  │
                └──────────────┘
```

Sedangkan untuk gRPC:

```text
.proto
   │
   ▼
generate.sh
   │
   ▼
Generated Go Code
   │
   ▼
server/grpc/
   │
   ▼
service/
   │
   ▼
repository/
   │
   ▼
PostgreSQL
```

---

# Kalau Ada Perubahan, File Mana yang Biasanya Ikut Berubah?

| Perubahan                     | File/Folder yang perlu diperiksa         |
| ----------------------------- | ---------------------------------------- |
| Menambah/mengubah tabel DB    | `migrations/`                            |
| Mengubah query SQL            | `repository/`                            |
| Mengubah business logic       | `service/`                               |
| Mengubah REST endpoint        | `api/`                                   |
| Mengubah gRPC contract        | `proto/`                                 |
| `.proto` berubah              | `generate.sh` → generate ulang → `grpc/` |
| Mengubah format REST response | `api/`, `common/response.go`             |
| Mengubah JWT                  | `utils/jwt.go`                           |
| Mengubah konfigurasi          | `config/`, `.env`                        |
| Menambah service baru         | `service/`, `api/`/`grpc/`, `main.go`    |
| Mengubah dependency Go        | `go.mod`, `go.sum`                       |
| Mengubah environment Docker   | `Dockerfile`, `docker-compose.yaml`      |

---

# Urutan Belajar / Membaca Code

Kalau baru masuk ke project ini, paling mudah memahami code dengan urutan:

```text
1. proto/
      ↓
2. api/ atau grpc/
      ↓
3. service/
      ↓
4. repository/
      ↓
5. migrations/
      ↓
6. database
```

Untuk memahami satu fitur secara utuh, misalnya **Transfer**, ikuti:

```text
transfer.proto
      ↓
transfer_handler.go
      ↓
transfer_service.go
      ↓
transfer_repository.go
      ↓
transfers table
```

Dengan cara ini kita bisa mengikuti **satu request dari client sampai database** tanpa harus membaca seluruh project sekaligus.
