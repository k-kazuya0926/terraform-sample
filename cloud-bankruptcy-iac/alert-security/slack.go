package main

import (
	"fmt"
	"github.com/slack-go/slack"
	"os"
)

var incomingWebhookURL = os.Getenv("INCOMING_WEBHOOK_URL")

// Block Kit
// https://api.slack.com/block-kit
func (f *Finding) postWebhook() error {
	webhookMessage := f.newWebhookMessage()
	return slack.PostWebhook(incomingWebhookURL, webhookMessage)
}

func (f *Finding) newWebhookMessage() *slack.WebhookMessage {
	description := newObject(":fire: Security Alert", f.Description)
	properties := []*slack.TextBlockObject{
		newObject("Severity", f.SeverityLabel),
		newObject("ProductName", f.ProductName),
	}
	descriptionBlock := slack.NewSectionBlock(description, properties, nil)

	recommendationMessage := fmt.Sprintf("%s\n%s", f.Text, f.Url)
	recommendation := newObject("Recommendation", recommendationMessage)
	recommendationBlock := slack.NewSectionBlock(recommendation, nil, nil)

	blockSet := []slack.Block{descriptionBlock, recommendationBlock}
	blocks := &slack.Blocks{BlockSet: blockSet}
	return &slack.WebhookMessage{Blocks: blocks}
}

func newObject(title, body string) *slack.TextBlockObject {
	text := fmt.Sprintf("*%s *\n %s", title, body)
	return slack.NewTextBlockObject("mrkdwn", text, false, false)
}
