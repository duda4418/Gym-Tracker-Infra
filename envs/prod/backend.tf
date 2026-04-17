terraform {
	backend "s3" {
		bucket         = "replace-with-bootstrap-state-bucket-name"
		key            = "envs/prod/terraform.tfstate"
		region         = "eu-central-1"
		dynamodb_table = "gym-tracker-terraform-locks"
		encrypt        = true
		# If you prefer S3 lockfile locking over DynamoDB, remove dynamodb_table and set use_lockfile = true.
	}
}
