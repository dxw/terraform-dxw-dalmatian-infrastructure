resource "aws_ssm_document" "infrastructure_vpc_transfer_s3_download" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  name          = "${local.resource_prefix_hash}-infrastructure-vpc-transfer-s3-download"
  document_type = "Session"
  content = templatefile("${path.root}/ssm-documents/s3-download.json.tpl", {
    command = local.infrastructure_vpc_transfer_ssm_download_command
  })
}

resource "aws_ssm_document" "infrastructure_vpc_transfer_s3_upload" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  name          = "${local.resource_prefix_hash}-infrastructure-vpc-transfer-s3-upload"
  document_type = "Session"
  content = templatefile("${path.root}/ssm-documents/s3-upload.json.tpl", {
    command = local.infrastructure_vpc_transfer_ssm_upload_command
  })
}
