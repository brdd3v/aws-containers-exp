"""An AWS Python Pulumi program"""

import pulumi
import pulumi_aws as aws
import pulumi_docker as docker


image_tag = "v1"

ecr_token = aws.ecr.get_authorization_token()

docker_provider = docker.Provider("docker_provider",
    host="unix:///var/run/docker.sock",

    registry_auth=[
        docker.provider.ProviderRegistryAuthArgs(
            address=ecr_token.proxy_endpoint,
            username=ecr_token.user_name,
            password=ecr_token.password
        )
    ]
)

ecr_repository = aws.ecr.Repository("ecr_repo",
    name="flask-app",
    force_delete=True
)

docker_image_name = ecr_repository.repository_url.apply(lambda repository_url: f"{repository_url}:{image_tag}")

docker_image = docker.Image("docker_image",
    image_name=docker_image_name,

    build=docker.DockerBuildArgs(
        context="../../app",
        platform="linux/amd64"
    )
)
