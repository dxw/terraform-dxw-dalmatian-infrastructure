{
  "schemaVersion": "1.0",
  "description": "Document to download from S3",
  "sessionType": "InteractiveCommands",
  "parameters": {
    "TargetUID": {
      "type": "String",
      "description": "The default unix UID of the target system",
      "default": ""
    },
    "TargetGID": {
      "type": "String",
      "description": "The default unix GID of the target system",
      "default": ""
    },
    "Source": {
      "type": "String",
      "description": "S3 Bucket source path"
    },
    "HostTarget": {
      "type": "String",
      "description": "Target path on instance"
    },
    "Recursive": {
      "type": "String",
      "description": "Recursive copy",
      "default": "--ignore-glacier-warnings",
      "allowedValues": [
        "--ignore-glacier-warnings",
        "--recursive"
      ]
    }
  },
  "properties": {
    "linux": {
      "commands": "${command}",
      "runAsElevated": true
    }
  }
}
