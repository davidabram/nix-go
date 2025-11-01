package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestRootHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	w := httptest.NewRecorder()

	router().ServeHTTP(w, req)

	body, _ := io.ReadAll(w.Result().Body)
	if !strings.Contains(string(body), "Hello from Chi + Nix!") {
		t.Fatalf("unexpected response body: %s", string(body))
	}
}
