package common

import (
    "log"
    "os"
)

var Logger *log.Logger

func InitLogger() {
    Logger = log.New(os.Stdout, "[WHOLESALES] ", log.LstdFlags|log.Lshortfile)
}
