package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"strings"

	authpb "github.com/izstoev10/ai_assistant/services/auth"
	notespb "github.com/izstoev10/ai_assistant/services/notes"
	"github.com/izstoev10/ai_assistant/services/notes/internal"
	"github.com/labstack/echo/v4"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/reflection"
	"google.golang.org/grpc/status"
)

func main() {
	// Connect to the auth service
	authConn, err := grpc.NewClient("localhost:8082", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("Failed to connect to auth service: %v", err)
	}
	defer authConn.Close()
	authClient := authpb.NewAuthClient(authConn)

	// Create Notes service with interceptor
	srv := grpc.NewServer(
		grpc.UnaryInterceptor(authUnaryInterceptor(authClient)),
	)

	notespb.RegisterNotesServer(srv, internal.NewNotesServer())
	reflection.Register(srv)

	// --- gRPC setup ---
	lis, err := net.Listen("tcp", ":50050")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	go func() {
		log.Println("📡 Notes gRPC server listening on :50050")
		if err := srv.Serve(lis); err != nil {
			log.Fatalf("Notes gRPC server error: %v", err)
		}
	}()

	// --- Temporary HTTP setup (to be removed once API Gateway is in place) ---
	e := echo.New()
	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Hello, World! from the Notes service (HTTP)")
	})

	log.Println("🌐 Notes HTTP server listening on :8081  (temporary)")
	if err := e.Start(":8081"); err != nil && !strings.Contains(err.Error(), "Server closed") {
		log.Fatalf("Notes HTTP server error: %v", err)
	}
}

func authUnaryInterceptor(authClient authpb.AuthClient) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
		md, ok := metadata.FromIncomingContext(ctx)
		if !ok {
			return nil, status.Error(codes.Unauthenticated, "metadata missing")
		}
		authH := md.Get("authorization")
		if len(authH) == 0 {
			return nil, status.Error(codes.Unauthenticated, "authorization token required")
		}
		// Expect "Bearer <token>"
		token := strings.TrimPrefix(authH[0], "Bearer ")
		resp, err := authClient.VerifyToken(ctx, &authpb.VerifyTokenRequest{Token: token})
		if err != nil {
			return nil, status.Error(codes.Unauthenticated, "invalid token")
		}

		// Attach user ID to context for handlers
		newCtx := context.WithValue(ctx, "userID", resp.UserId)
		return handler(newCtx, req)
	}
}
