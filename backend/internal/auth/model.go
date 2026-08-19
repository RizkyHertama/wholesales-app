package auth

type Company struct {
	ID            int64   `db:"id"`
	Name          string  `db:"name"`
	Email         string  `db:"email"`
	PasswordHash  string  `db:"password_hash"`
	BankCode      string  `db:"bank_code"`
	AccountNumber string  `db:"account_number"`
	Balance       float64 `db:"balance"`
}
