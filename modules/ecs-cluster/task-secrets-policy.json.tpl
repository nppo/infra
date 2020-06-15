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
                "arn:aws:secretsmanager:eu-central-1:322480324822:secret:dev/search-portal/django-TPQRKj",
                "arn:aws:secretsmanager:eu-central-1:322480324822:secret:dev/search-portal/surfconext-YAf8dw",
                "arn:aws:secretsmanager:eu-central-1:322480324822:secret:dev/search-portal/elastic-ByS7CH",
                "${postgres_credentials_application_arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetRandomPassword",
            "Resource": "*"
        }
    ]
}
