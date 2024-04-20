package main

import (
	"context"

	"github.com/aws/aws-lambda-go/lambda"
)

type MyEvent struct {
}

func HandleRequest(ctx context.Context, e *MyEvent) (*string, error) {

	str := "bye world"
	return &str, nil
}

func add(a, b int) int {
	return a + b
}

func main() {
	lambda.Start(HandleRequest)
}
