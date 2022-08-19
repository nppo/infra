[
    {
        "name": "celery-worker-container",
        "image": "${docker_registry}/harvester:${env}",
        "cpu": 0,
        "essential": true,
        "command": [
            "celery",
            "-A",
            "harvester",
            "worker",
            "--loglevel=info",
            "-n=main-worker@%h"
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
        "name": "celery-beat-container",
        "image": "${docker_registry}/harvester:${env}",
        "cpu": 512,
        "essential": true,
        "command": [
            "celery",
            "-A",
            "harvester",
            "beat",
            "-s",
            "/tmp/celerybeat-schedule"
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
        "name": "analyzer",
        "image": "${docker_registry}/analyzer:latest",
        "essential": true,
        "portMappings": [
            {
                "hostPort": 9090,
                "protocol": "tcp",
                "containerPort": 9090
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
