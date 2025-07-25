package internal

import (
	"context"

	authpb "github.com/izstoev10/ai_assistant/services/auth"
)

type AuthServer struct {
	authpb.UnimplementedAuthServer
}

func NewAuthServer() *AuthServer {
	return &AuthServer{}
}

func (s *AuthServer) Login(ctx context.Context, req *authpb.LoginRequest) (*authpb.LoginResponse, error) {
	return &authpb.LoginResponse{
		Token: "test",
	}, nil
}

func (s *AuthServer) VerifyToken(ctx context.Context, req *authpb.VerifyTokenRequest) (*authpb.VerifyTokenResponse, error) {
	return &authpb.VerifyTokenResponse{
		UserId: "test",
	}, nil
}
