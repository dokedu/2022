package graph

// This file will be automatically regenerated based on the schema, any resolver implementations
// will be copied through when generating and any unknown code will be moved to the end.
// Code generated by github.com/99designs/gqlgen version v0.17.29

import (
	"context"
	"example/pkg/db"
	"example/pkg/graph/model"
	"fmt"
	"time"
)

// SignIn is the resolver for the signIn field.
func (r *mutationResolver) SignIn(ctx context.Context, input model.SignInInput) (*model.SignInPayload, error) {
	panic(fmt.Errorf("not implemented: SignIn - signIn"))
}

// Owner is the resolver for the owner field.
func (r *organisationResolver) Owner(ctx context.Context, obj *db.Organisation) (*db.User, error) {
	panic(fmt.Errorf("not implemented: Owner - owner"))
}

// Users is the resolver for the users field.
func (r *organisationResolver) Users(ctx context.Context, obj *db.Organisation) ([]*db.User, error) {
	panic(fmt.Errorf("not implemented: Users - users"))
}

// Me is the resolver for the me field.
func (r *queryResolver) Me(ctx context.Context) (*db.User, error) {
	userId := "00f_dsi0rH1bR4kGMPmPY"
	organisationID := "vTLyQPq-eXk_aHQuKw47A"

	user, err := r.DB.GetUserByID(ctx, db.GetUserByIDParams{
		ID:             userId,
		OrganisationID: organisationID,
	})

	// if error "sql: no rows in result set" return custom error message
	if err != nil && err.Error() == "sql: no rows in result set" {
		return nil, fmt.Errorf("user not found")
	}

	if err != nil {
		return nil, err
	}

	return &user, nil
}

// Organisations is the resolver for the organisations field.
func (r *queryResolver) Organisations(ctx context.Context) ([]*db.Organisation, error) {
	panic(fmt.Errorf("not implemented: Organisations - organisations"))
}

// Organisation is the resolver for the organisation field.
func (r *queryResolver) Organisation(ctx context.Context, id string) (*db.Organisation, error) {
	panic(fmt.Errorf("not implemented: Organisation - organisation"))
}

// Users is the resolver for the users field.
func (r *queryResolver) Users(ctx context.Context) ([]*db.User, error) {
	panic(fmt.Errorf("not implemented: Users - users"))
}

// User is the resolver for the user field.
func (r *queryResolver) User(ctx context.Context, id string) (*db.User, error) {
	panic(fmt.Errorf("not implemented: User - user"))
}

// Tasks is the resolver for the tasks field.
func (r *queryResolver) Tasks(ctx context.Context) ([]*db.Task, error) {
	panic(fmt.Errorf("not implemented: Tasks - tasks"))
}

// Task is the resolver for the task field.
func (r *queryResolver) Task(ctx context.Context, id string) (*db.Task, error) {
	panic(fmt.Errorf("not implemented: Task - task"))
}

// User is the resolver for the user field.
func (r *taskResolver) User(ctx context.Context, obj *db.Task) (*db.User, error) {
	userId := "00f_dsi0rH1bR4kGMPmPY"
	organisationID := "vTLyQPq-eXk_aHQuKw47A"

	user, err := r.DB.GetUserByID(ctx, db.GetUserByIDParams{
		ID:             userId,
		OrganisationID: organisationID,
	})

	if err != nil {
		return nil, err
	}

	return &user, nil
}

// DeletedAt is the resolver for the deletedAt field.
func (r *taskResolver) DeletedAt(ctx context.Context, obj *db.Task) (*time.Time, error) {
	// return null
	return nil, nil

	//panic(fmt.Errorf("not implemented: DeletedAt - deletedAt"))
}

// Tasks is the resolver for the tasks field.
func (r *userResolver) Tasks(ctx context.Context, obj *db.User) ([]*db.Task, error) {
	userId := "00f_dsi0rH1bR4kGMPmPY"
	organisationID := "vTLyQPq-eXk_aHQuKw47A"

	tasks, err := r.DB.GetTasksByUserID(ctx, db.GetTasksByUserIDParams{
		UserID:         userId,
		OrganisationID: organisationID,
	})

	if err != nil {
		return nil, err
	}

	// return tasks as pointer
	var tasksPtr []*db.Task
	for _, task := range tasks {
		tasksPtr = append(tasksPtr, &task)
	}

	return tasksPtr, nil

	//panic(fmt.Errorf("not implemented: Tasks - tasks"))
}

// Mutation returns MutationResolver implementation.
func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

// Organisation returns OrganisationResolver implementation.
func (r *Resolver) Organisation() OrganisationResolver { return &organisationResolver{r} }

// Query returns QueryResolver implementation.
func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

// Task returns TaskResolver implementation.
func (r *Resolver) Task() TaskResolver { return &taskResolver{r} }

// User returns UserResolver implementation.
func (r *Resolver) User() UserResolver { return &userResolver{r} }

type mutationResolver struct{ *Resolver }
type organisationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
type taskResolver struct{ *Resolver }
type userResolver struct{ *Resolver }
