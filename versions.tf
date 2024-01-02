terraform {
  required_version = ">= 1.6.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.1"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3.2"
    }
  }
}
