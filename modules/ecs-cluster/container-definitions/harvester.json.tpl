[
    {
        "name": "harvester-container",
        "image": "${docker_registry}/harvester:${env}",
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
                "name": "PYTHONUNBUFFERED",
                "value": "1"
            },
            {
                "name": "APPLICATION_MODE",
                "value": "${application_mode}"
            },
            {
                "name": "APPLICATION_PROJECT",
                "value": "${application_project}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/harvester",
                "awslogs-region": "eu-central-1",
                "awslogs-stream-prefix": "${env}",
                "awslogs-multiline-pattern": "^\\[?\\d\\d\\d\\d\\-\\d\\d\\-\\d\\d \\d\\d:\\d\\d:\\d\\d,\\d\\d\\d"
            }
        }
    },
    {
        "name": "harvester-nginx",
        "image": "${docker_registry}/harvester-nginx:${env}",
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
                "awslogs-group": "/ecs/harvester",
                "awslogs-region": "eu-central-1",
                "awslogs-stream-prefix": "${env}-nginx",
                "awslogs-multiline-pattern": "^\\[?\\d\\d\\d\\d\\-\\d\\d\\-\\d\\d \\d\\d:\\d\\d:\\d\\d,\\d\\d\\d"
            }
        }
    },
    {
        "name": "flower-container",
        "image": "${docker_registry}/harvester:${env}",
        "cpu": 0,
        "essential": true,
        "portMappings": [
            {
                "hostPort": 5555,
                "protocol": "tcp",
                "containerPort": 5555
            }
        ],
        "command": [
            "celery",
            "-A",
            "harvester",
            "flower",
            "--url_prefix=flower"
        ],
        "environment": [
            {
                "name": "PYTHONUNBUFFERED",
                "value": "1"
            },
            {
                "name": "APPLICATION_MODE",
                "value": "${application_mode}"
            },
            {
                "name": "APPLICATION_PROJECT",
                "value": "${application_project}"
            }
        ],
        "secrets": [
            {
                "name": "FLOWER_BASIC_AUTH",
                "valueFrom": "${flower_secret}"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/harvester",
                "awslogs-region": "eu-central-1",
                "awslogs-stream-prefix": "${env}",
                "awslogs-multiline-pattern": "^\\[?\\d\\d\\d\\d\\-\\d\\d\\-\\d\\d \\d\\d:\\d\\d:\\d\\d,\\d\\d\\d"
            }
        }
    }
]
