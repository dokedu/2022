package status

type ApiError string

var (
	ErrBadRequest   ApiError = "bad request"
	ErrNotFound     ApiError = "not found"
	ErrIntegrity    ApiError = "integrity issue"
	ErrInternal     ApiError = "internal server error"
	ErrUnauthorized ApiError = "unauthorized"
	ErrForbidden    ApiError = "forbidden"

	ResOK = "OK"
)
