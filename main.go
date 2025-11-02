package main

import (
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func router() http.Handler {
	r := chi.NewRouter()

	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.StripSlashes)
	r.Use(middleware.Timeout(60 * time.Second))

	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain")
		w.WriteHeader(http.StatusOK)
		if _, err := w.Write([]byte("Hello from Chi + Nix!\n")); err != nil {
			slog.Error("Failed to write response", "error", err)
		}
	})

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		if _, err := w.Write([]byte(`{"status":"ok"}`)); err != nil {
			slog.Error("Failed to write response", "error", err)
		}
	})

	return r
}

func getAddr() string {
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":8080"
	}
	return addr
}

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	addr := getAddr()

	slog.Info("Starting server", "addr", addr)

	srv := &http.Server{
		Addr:         addr,
		Handler:      router(),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	if err := srv.ListenAndServe(); err != nil {
		slog.Error("Server failed", "error", err)
		os.Exit(1)
	}
}
