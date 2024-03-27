def lambda_handler(event, context):
  print("Hello World!")

  # Once you're lambda has deployed, upload the new zip to the
  # custom lambdas S3 bucket, and it will be deployed here
  #
  # eg:
  # aws s3 cp <new_zipped_function> s3://<custom_lambdas_s3_bucket>/<function_zip_s3_key>
  # aws lambda update-function-code \
  #   --function-name <function_name> \
  #   --s3-bucket <custom_lambdas_s3_bucket> \
  #   --s3-key <function_zip_s3_key>
  #
  # Ensure the `function_zip_s3_key` matches the name defined in the dalmatian infrastructure tfvars,
  # otherwise you will run the risk of the function code being reverted
