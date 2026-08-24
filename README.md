Struktur Folder & Fungsinya
Urutan folder yang biasanya dibuat
proto
Tempat file .proto (kontrak gRPC).

Dari sini di‑generate file .pb.go.

Kalau ada perubahan kolom di DB → biasanya juga perlu update .proto supaya field di request/response sesuai.

repository
Berisi query SQL / akses DB.

Misalnya company_repository.go untuk CRUD company.

Kalau ada perubahan kolom DB, repository harus diubah (query SELECT/INSERT/UPDATE).

service
Berisi logika bisnis.

Contoh: transfer_service.go cek saldo, validasi, lalu panggil repository.

Kalau ada kolom baru di DB, service biasanya ikut berubah (misalnya ada field status baru → service harus set nilainya).

grpc-handler
Implementasi interface dari .proto.

Contoh: CompanyServer punya method CreateCompany.

Handler ini memanggil service.

Kalau .proto berubah (misalnya ada field baru di request), handler harus diupdate.

common/utils
Koneksi DB, logger, JWT, config.

Jarang berubah kecuali ada kebutuhan global (misalnya ganti driver DB).

cmd
Entry point aplikasi.

Di sini kita register gRPC server dan semua handler.

Kalau ada service baru, harus ditambahkan di sini.
