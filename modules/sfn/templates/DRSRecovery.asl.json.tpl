{
  "Comment": "Start Recovery post disaster",
  "StartAt": "Set Input as Variable",
  "TimeoutSeconds": 3600,
  "States": {
    "Set Input as Variable": {
      "Type": "Pass",
      "Next": "DescribeSourceServers",
      "Assign": {
        "SourceServerID": "{% $states.input.SourceServerID %}",
        "IsDrill": "{% $states.input.IsDrill %}",
        "RecoverySubnetID": "{% $states.input.RecoverySubnetID %}"
      }
    },
    "DescribeSourceServers": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:drs:describeSourceServers",
      "Next": "DRS Tag Source Instance",
      "Arguments": {
        "Filters": {
          "SourceServerIDs": [
            "{% $SourceServerID %}"
          ]
        }
      },
      "Assign": {
        "SourceInstanceID": "{% $states.result.Items[0].SourceProperties.IdentificationHints.AwsInstanceID %}"
      }
    },
    "DRS Tag Source Instance": {
      "Type": "Task",
      "Arguments": {
        "Resources": [
          "{% $SourceInstanceID %}"
        ],
        "Tags": [
          {
            "Key": "AWSDRS",
            "Value": "AllowLaunchingIntoThisInstance"
          }
        ]
      },
      "Resource": "arn:aws:states:::aws-sdk:ec2:createTags",
      "Next": "Stop Source Instance",
      "Comment": "Tag Source instance to mark it ready for DRS failback & Protected\nhttps://docs.aws.amazon.com/drs/latest/userguide/default-drs-launch-into-source-instance.html#launch-into-source-instance-pre-requisites"
    },
    "Stop Source Instance": {
      "Type": "Task",
      "Arguments": {
        "InstanceIds": [
          "{% $SourceInstanceID %}"
        ],
        "Force": true
      },
      "Resource": "arn:aws:states:::aws-sdk:ec2:stopInstances",
      "Next": "Get Source Launch Configuration",
      "TimeoutSeconds": 600,
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "BackoffRate": 2,
          "MaxAttempts": 3,
          "IntervalSeconds": 10,
          "Comment": "Retry Stopping Source Instance"
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Ignore error if not drill"
        }
      ]
    },
    "Ignore error if not drill": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "Get Source Launch Configuration",
          "Condition": "{% ($IsDrill) = (false) %}"
        }
      ],
      "Default": "Unable to stop source instance"
    },
    "Unable to stop source instance": {
      "Type": "Fail"
    },
    "Get Source Launch Configuration": {
      "Type": "Task",
      "Arguments": {
        "SourceServerID": "{% $SourceServerID %}"
      },
      "Resource": "arn:aws:states:::aws-sdk:drs:getLaunchConfiguration",
      "Next": "StartRecovery",
      "Assign": {
        "LaunchTemplateID": "{% $states.result.Ec2LaunchTemplateID %}"
      }
    },
    "StartRecovery": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:drs:startRecovery",
      "Next": "Wait 10 Seconds",
      "Arguments": {
        "IsDrill": "{% $IsDrill %}",
        "SourceServers": [
          {
            "SourceServerID": "{% $SourceServerID %}"
          }
        ]
      },
      "Assign": {
        "JobID": "{% $states.result.Job.JobID %}"
      },
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Comment": "Unable to start recovery job",
          "Next": "Catch Start Recovery Error"
        }
      ]
    },
    "Catch Start Recovery Error": {
      "Type": "Pass",
      "Next": "Is drill",
      "Assign": {
        "Error": "{% $states.input.Error %}",
        "Cause": "{% $states.input.Cause %}"
      }
    },
    "Wait 10 Seconds": {
      "Type": "Wait",
      "Next": "DescribeJobs",
      "Seconds": 10
    },
    "DescribeJobs": {
      "Type": "Task",
      "Arguments": {
        "Filters": {
          "JobIDs": [
            "{% $JobID %}"
          ]
        }
      },
      "Resource": "arn:aws:states:::aws-sdk:drs:describeJobs",
      "Next": "Is recovery job success"
    },
    "Is recovery job success": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "Wait 10 Seconds",
          "Condition": "{% $not(($states.input.Items.Status) = (\"COMPLETED\")) %}"
        },
        {
          "Next": "Retrieve recovery instance ID",
          "Condition": "{% (($states.input.Items.ParticipatingServers.LaunchStatus) = (\"LAUNCHED\")) %}"
        }
      ],
      "Default": "Describe Recovery Job Log Items"
    },
    "Describe Recovery Job Log Items": {
      "Type": "Task",
      "Arguments": {
        "JobID": "{% $JobID %}"
      },
      "Resource": "arn:aws:states:::aws-sdk:drs:describeJobLogItems",
      "Next": "Is drill"
    },
    "Is drill": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "Start Source Instance",
          "Condition": "{% ($IsDrill) = (true) %}"
        }
      ],
      "Default": "Recovery job failed"
    },
    "Start Source Instance": {
      "Type": "Task",
      "Arguments": {
        "InstanceIds": [
          "{% $SourceInstanceID %}"
        ]
      },
      "Resource": "arn:aws:states:::aws-sdk:ec2:startInstances",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "BackoffRate": 2,
          "IntervalSeconds": 5,
          "MaxAttempts": 3,
          "Comment": "Retry on starting instance failed"
        }
      ],
      "Next": "Recovery job failed"
    },
    "Retrieve recovery instance ID": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:drs:describeRecoveryInstances",
      "Next": "Wait 30 seconds",
      "Assign": {
        "RecoveryInstanceID": "{% $states.result.Items[0].RecoveryInstanceID %}"
      },
      "Arguments": {
        "Filters": {
          "SourceServerIDs": [
            "{% $SourceServerID %}"
          ]
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "BackoffRate": 2,
          "IntervalSeconds": 3,
          "MaxAttempts": 3
        }
      ]
    },
    "Wait 30 seconds": {
      "Type": "Wait",
      "Seconds": 30,
      "Comment": "Wait for instance becomes ready running",
      "Next": "Describe Recovery Instance Status"
    },
    "Describe Recovery Instance Status": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:ec2:describeInstanceStatus",
      "Next": "Ensuring recovery instance is running",
      "Arguments": {
        "InstanceIds": [
          "{% $RecoveryInstanceID %}"
        ]
      }
    },
    "Ensuring recovery instance is running": {
      "Type": "Choice",
      "Choices": [
        {
          "Next": "Protect Recovered Instance",
          "Condition": "{% (($states.input.InstanceStatuses[0].InstanceState.Code) = (16) and ($states.input.InstanceStatuses.InstanceStatus.Status) = (\"ok\")) %}"
        }
      ],
      "Default": "Wait 30 seconds"
    },
    "Protect Recovered Instance": {
      "Type": "Task",
      "Arguments": {
        "RecoveryInstanceID": "{% $RecoveryInstanceID %}"
      },
      "Resource": "arn:aws:states:::aws-sdk:drs:reverseReplication",
      "Comment": "Protect Recovered Instance by calling Reverse Instance API",
      "Next": "Success",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "BackoffRate": 2,
          "MaxAttempts": 3,
          "Comment": "Retry when recovery instance is not ready",
          "IntervalSeconds": 10
        }
      ],
      "TimeoutSeconds": 300
    },
    "Success": {
      "Type": "Succeed"
    },
    "Recovery job failed": {
      "Type": "Fail",
      "Error": "{% $exists($Error) ? $Error : \"Unable to start recovery\" %}",
      "Cause": "{% $exists($Cause) ? $Cause : \"Something wrong with start recovery\" %}"
    }
  },
  "QueryLanguage": "JSONata"
}