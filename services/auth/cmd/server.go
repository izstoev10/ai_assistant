package main

import (
	"context"
	"net/http"

	authpb "github.com/izstoev10/ai-assistant/services/auth/auth_grpc"
	"github.com/labstack/echo/v4"
)

func main() {
	e := echo.New()
	e.GET("/", func(c echo.Context) error {
		// call the auth service
		authClient := authpb.NewAuthClient(conn)
		authClient.Login(context.Background(), &authpb.LoginRequest{
			Email:    "test@test.com",
			Password: "test",
		})
		return c.String(http.StatusOK, "Hello, World from the auth service")
	})
	e.Logger.Fatal(e.Start(":8082"))
}
