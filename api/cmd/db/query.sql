-- name: ListUsers :many
SELECT *
FROM users
WHERE organisation_id = $1;

-- name: GetOrganisationByID :one
SELECT *
FROM organisations
WHERE id = $1;

-- name: GetUserByID :one
SELECT *
FROM users
WHERE id = $1
  AND organisation_id = $2;

-- name: ListTasks :many
SELECT *
FROM tasks
WHERE organisation_id = $1;

-- name: GetTaskByID :one
SELECT *
FROM tasks
WHERE id = $1
  AND organisation_id = $2;

-- name: GetTasksByUserID :many
SELECT *
FROM tasks
WHERE user_id = $1
  AND organisation_id = $2;

-- name: CreateTask :one
INSERT INTO tasks (organisation_id, user_id, name, description)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: UpdateTask :one
UPDATE tasks
SET name        = $1,
    description = $2
WHERE id = $3
  AND organisation_id = $4
RETURNING *;

-- name: DeleteTask :one
DELETE
FROM tasks
WHERE id = $1
  AND organisation_id = $2
RETURNING *;