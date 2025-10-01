import boto3
import botocore

import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

drs_client = boto3.client("drs")
ec2_client = boto3.client("ec2")


def get_source_instance_id(source_server_id):
    try:
        logger.info(f"Retrieving source server details for {source_server_id}")
        response = drs_client.describe_source_servers(
            filters={"sourceServerIDs": [source_server_id]}
        )

        response = response.get("items")
        if len(response) == 0:
            logger.error(f"No source server found with ID: {source_server_id}")
            return None
        source_server = response[0]  # Get the first (and should be only) item
        source_instance_id = (
            source_server.get("sourceProperties")
            .get("identificationHints")
            .get("awsInstanceID")
        )
        logger.info(f"Retrieved source instance_id: {source_instance_id} successfully")
        return source_instance_id
    except botocore.exceptions.ClientError as e:
        logger.error(f"Error retrieving source server {source_server_id}: {e}")
        return None


def get_drs_created_launch_template_id(source_server_id):
    try:
        response = drs_client.get_launch_configuration(sourceServerID=source_server_id)
        drs_created_launch_template_id = response.get("ec2LaunchTemplateID", "")
        return drs_created_launch_template_id
    except botocore.exceptions.ClientError as e:
        logger.error(
            f"Error retrieving DRS launch template for {source_server_id}: {e}"
        )
        return None


def retrieve_source_server_details(source_server_id):
    source_instance_id = get_source_instance_id(source_server_id)
    drs_created_launch_template_id = get_drs_created_launch_template_id(
        source_server_id
    )
    return {
        "source_server_id": source_server_id,
        "source_instance_id": source_instance_id,
        "drs_created_launch_template_id": drs_created_launch_template_id,
    }


def get_launch_template_data(source_instance_id):
    try:
        launch_template_data = ec2_client.get_launch_template_data(
            InstanceId=source_instance_id
        ).get("LaunchTemplateData", {})

        return launch_template_data
    except botocore.exceptions.ClientError as e:
        logger.error(f"Error retrieving EC2 instance {aws_instance_id}: {e}")
        return None


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    source_server_arn = event.get("resources", [None])[0]
    if not source_server_arn:
        logger.error("No source server ARN found in event resources.")
        return
    source_server_id = source_server_arn.split("/")[-1]

    source_server_details = retrieve_source_server_details(source_server_id)
    source_instance_id, drs_created_launch_template_id = (
        source_server_details.get("source_instance_id"),
        source_server_details.get("drs_created_launch_template_id"),
    )

    source_template_data = get_launch_template_data(source_instance_id)
    logger.info(f"Launch template {source_template_data}")
    ec2_client.create_launch_template_version(
        LaunchTemplateId=drs_created_launch_template_id,
        SourceVersion="$Default",
        LaunchTemplateData=source_template_data,
    )

    logger.info(
        f"Duplicated launch template from source instance {source_instance_id} to source server {source_server_id} launch template successfully"
    )

    return {
        "statusCode": 200,
        "body": "Launch template duplicated successfully",
    }
