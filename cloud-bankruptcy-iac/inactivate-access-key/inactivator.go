package main

import (
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/iam"
	"time"
)

const ExpirationDay = 90.0

func inactivate(svc *iam.IAM, accessKey *iam.AccessKeyMetadata) error {
	current := time.Now()
	duration := current.Sub(*accessKey.CreateDate)
	durationDay := duration.Hours() / 24
	if durationDay < ExpirationDay {
		return nil
	}

	input := &iam.UpdateAccessKeyInput{
		AccessKeyId: accessKey.AccessKeyId,
		UserName:    accessKey.UserName,
		Status:      aws.String(iam.StatusTypeInactive),
	}

	// 本来は更新実行
	fmt.Printf("input: %v\n", input)
	//_, err := svc.UpdateAccessKey(input)
	//if err != nil {
	//	return fmt.Errorf("failed UpdateAccessKey: %s", err)
	//}

	return nil
}
