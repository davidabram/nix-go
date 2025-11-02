package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestRootHandler(t *testing.T) {
	tests := []struct {
		name           string
		path           string
		expectedStatus int
		expectedBody   string
	}{
		{
			name:           "root endpoint",
			path:           "/",
			expectedStatus: http.StatusOK,
			expectedBody:   "Hello from Chi + Nix!",
		},
		{
			name:           "health endpoint",
			path:           "/health",
			expectedStatus: http.StatusOK,
			expectedBody:   `{"status":"ok"}`,
		},
		{
			name:           "not found",
			path:           "/nonexistent",
			expectedStatus: http.StatusNotFound,
			expectedBody:   "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, tt.path, http.NoBody)
			w := httptest.NewRecorder()

			router().ServeHTTP(w, req)

			if w.Code != tt.expectedStatus {
				t.Errorf("expected status %d, got %d", tt.expectedStatus, w.Code)
			}

			if tt.expectedBody != "" {
				body, _ := io.ReadAll(w.Result().Body)
				if !strings.Contains(string(body), tt.expectedBody) {
					t.Errorf("expected body to contain %q, got %q", tt.expectedBody, string(body))
				}
			}
		})
	}
}

func TestGetAddr(t *testing.T) {
	tests := []struct {
		name     string
		envValue string
		expected string
	}{
		{
			name:     "default addr",
			envValue: "",
			expected: ":8080",
		},
		{
			name:     "custom addr",
			envValue: ":3000",
			expected: ":3000",
		},
		{
			name:     "host and port",
			envValue: "localhost:9090",
			expected: "localhost:9090",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.envValue != "" {
				t.Setenv("ADDR", tt.envValue)
			}

			addr := getAddr()
			if addr != tt.expected {
				t.Errorf("expected addr %q, got %q", tt.expected, addr)
			}
		})
	}
}
