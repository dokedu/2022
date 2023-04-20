package middleware

import (
	"context"
	"net/http"
	"strings"
)

func Auth() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			jwt := r.Header.Get("Authorization")
			jwt = strings.TrimPrefix(jwt, "Bearer ")

			// Validate JWT
			if jwt == "" {
				next.ServeHTTP(w, r)
				return
			}

			ctx := context.WithValue(r.Context(), "jwt", jwt)
			r = r.WithContext(ctx)

			// Do stuff here
			next.ServeHTTP(w, r)
		})
	}
}
