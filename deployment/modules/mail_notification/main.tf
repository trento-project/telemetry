resource "aws_sns_topic" "state_updates" {
  name       = "${var.name}-sns-topic-${var.environment}"

  tags = {
    Name        = "${var.name}-task-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "state_updates_subscription" {
  count     = length(var.sns_subscription_email_address_list)
  topic_arn = aws_sns_topic.state_updates.id
  protocol  = "email"
  endpoint  = element(var.sns_subscription_email_address_list, count.index)
}

resource "aws_cloudwatch_event_rule" "state_updates_watch" {
  name        = "${var.name}-cloudwatch-rule-${var.environment}"
  description = "Notify Telemetry service tasks state changes"

  event_pattern = <<EOF
  {
    "source": [
      "aws.ecs"
    ],
    "detail-type": [
      "ECS Task State Change"
    ],
    "detail": {
      "clusterArn": [
        "${var.ecs_arn}"
      ]
    }
  }
EOF
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.state_updates_watch.name
  arn       = aws_sns_topic.state_updates.id

  input_transformer {
    input_paths = {
      stoppedReason = "$.detail.stoppedReason",
      lastStatus    = "$.detail.lastStatus",
      group         = "$.detail.group",
    }
    input_template = "\"The container <group> in ${var.name}/${var.environment} got <lastStatus> due to <stoppedReason>\""
  }
}

resource "aws_sns_topic_policy" "allow_emails" {
  arn    = aws_sns_topic.state_updates.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"
  statement {
    effect = "Allow"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [data.aws_caller_identity.current.account_id]
    }

    resources = [aws_sns_topic.state_updates.arn]
    sid = "__default_statement_ID"
  }

  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.state_updates.arn]
    sid       = "AWSEvents_${var.name}_${var.environment}"
  }
}
