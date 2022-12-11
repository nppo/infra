[
    {
        "name": "middleware-container",
        "image": "${docker_registry}/middleware:${env}",
        "cpu": 0,
        "essential": true,
        "portMappings": [
            {
                "hostPort": 8080,
                "protocol": "tcp",
                "containerPort": 8080
            }
        ],
        "environment": [
            {
                "name": "APPLICATION_MODE",
                "value": "${application_mode}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/middleware",
                "awslogs-region": "eu-central-1",
                "awslogs-stream-prefix": "${env}",
                "awslogs-multiline-pattern": "^\\[?\\d\\d\\d\\d\\-\\d\\d\\-\\d\\d \\d\\d:\\d\\d:\\d\\d,\\d\\d\\d"
            }
        }
    },
    {
        "name": "middleware-nginx",
        "image": "${docker_registry}/middleware-nginx:${env}",
        "essential": true,
        "portMappings": [
            {
                "hostPort": 80,
                "protocol": "tcp",
                "containerPort": 80
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/middleware",
                "awslogs-region": "eu-central-1",
                "awslogs-stream-prefix": "${env}",
                "awslogs-multiline-pattern": "^\\[?\\d\\d\\d\\d\\-\\d\\d\\-\\d\\d \\d\\d:\\d\\d:\\d\\d,\\d\\d\\d"
            }
        }
    }
]
