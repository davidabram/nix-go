package main

import (
	"fmt"
	"net/http"

	"github.com/go-chi/chi/v5"
)

func router() http.Handler {
	r := chi.NewRouter()
	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Hello from Chi + Nix!")
	})
	return r
}

func main() {
	fmt.Println("Server listening on :8080")
	http.ListenAndServe(":8080", router())
}
