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
                "${surfconext_credentials_arn}",
                "${elastic_search_credentials_arn}",
                "${postgres_credentials_application_arn}",
                "${eduterm_credentials_arn}",
                "${deepl_key_arn}"
                %{if monitor_uptime}
                ,"${surfrapportage_credentials_arn}"
                %{endif}
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetRandomPassword",
            "Resource": "*"
        }
    ]
}
