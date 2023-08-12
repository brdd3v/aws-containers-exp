"""An AWS Python Pulumi program"""

import pulumi
import pulumi_aws as aws


image_tag = "v1"

ecr_repository = aws.ecr.get_repository(name="flask-app")

service_role = aws.iam.get_role(name="AppRunnerECRAccessRole")

app_runner_svc = aws.apprunner.Service("svc",
    service_name="flask-app-svc",

    source_configuration=aws.apprunner.ServiceSourceConfigurationArgs(
        authentication_configuration=aws.apprunner.ServiceSourceConfigurationAuthenticationConfigurationArgs(
            access_role_arn=service_role.arn
        ),

        image_repository=aws.apprunner.ServiceSourceConfigurationImageRepositoryArgs(
            image_configuration=aws.apprunner.ServiceSourceConfigurationImageRepositoryImageConfigurationArgs(
                port="5000"
            ),
            image_identifier=f"{ecr_repository.repository_url}:{image_tag}",
            image_repository_type="ECR"
        ),
        auto_deployments_enabled=False
    ),
    instance_configuration=aws.apprunner.ServiceInstanceConfigurationArgs(
        cpu="512",  # default: 1024
        memory="1024"  # default: 2048
    )
)

service_url = app_runner_svc.service_url.apply(lambda service_url: f"{service_url}")

pulumi.export("service_url", service_url)
