{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:StartTask",
        "ecs:StopTask",
        "ecs:DescribeTasks",
        "ecs:RunTask"
      ],
      "Resource": ["arn:aws:ecs:*:*:task/*"],
      "Condition": {
        "ArnEquals": {
          "ecs:cluster": "${cluster_arn}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateService",
        "ecs:DeleteService",
        "ecs:DescribeServices",
        "ecs:UpdateService"
      ],
      "Resource": ["arn:aws:ecs:*:*:service/*"],
      "Condition": {
        "ArnEquals": {
          "ecs:cluster": "${cluster_arn}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:ListTasks",
        "ecs:ListServices"
      ],
      "Resource": ["*"],
      "Condition": {
        "ArnEquals": {
          "ecs:cluster": "${cluster_arn}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeClusters"
      ],
      "Resource": ["${cluster_arn}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DeregisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:ListClusters",
        "ecs:ListTaskDefinitionFamilies",
        "ecs:ListTaskDefinitions",
        "ecs:RegisterTaskDefinition"
      ],
      "Resource": ["*"]
    }
  ]
}