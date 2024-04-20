package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
)

type Events struct {
	Parameters map[string]string `json:"pathParameters"`
}

func HandleRequest(ctx context.Context, e Events) (*string, error) {

	fmt.Println(e)

	str := "hello world"

	return &str, nil
}

func main() {
	lambda.Start(HandleRequest)
}
