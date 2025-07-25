package main

import (
	"net/http"

	authpb "github.com/izstoev10/ai_assistant/services/auth"
	"github.com/izstoev10/ai_assistant/services/auth/internal"
	"github.com/labstack/echo/v4"
	"google.golang.org/grpc"
)

func main() {
	e := echo.New()
	s := grpc.NewServer()

	authpb.RegisterAuthServer(s, internal.NewAuthServer())

	e.GET("/", func(c echo.Context) error {
		// call the auth service
		return c.String(http.StatusOK, "Hello, World from the auth service")
	})
	e.Logger.Fatal(e.Start(":8082"))
}
