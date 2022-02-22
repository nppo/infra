{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "${django_credentials_arn}",
                "${postgres_credentials_application_arn}",
                "${flower_credentials_arn}",
                "${eduterm_credentials_arn}",
                "${sharekit_credentials_arn}",
                "${deepl_key_arn}",
                "${harvester_api_key_arn}",
                "${hanze_credentials_harvester}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetRandomPassword",
            "Resource": "*"
        }
    ]
}
