package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
)

type MyEvent struct {
	UserName     string `json:"user_name"`
	UserPassword string `json:"user_password"`
}

func HandleRequest(ctx context.Context, e *MyEvent) (*string, error) {

	uName, uPassword := e.UserName, e.UserPassword

	str := fmt.Sprintf("username : %s password : %s", uName, uPassword)
	return &str, nil
}

func main() {
	lambda.Start(HandleRequest)
}
