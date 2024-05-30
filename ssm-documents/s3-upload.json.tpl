{
  "schemaVersion": "1.0",
  "description": "Document to uplaod to S3",
  "sessionType": "InteractiveCommands",
  "parameters": {
    "Source": {
      "type": "String",
      "description": "file source path"
    },
    "S3Target": {
      "type": "String",
      "description": "s3 bucket path"
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
