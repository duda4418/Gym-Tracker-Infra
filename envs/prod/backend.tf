terraform {
	backend "s3" {
		bucket         = "gym-tracker-tf-state-606008290381-52451"
		key            = "envs/prod/terraform.tfstate"
		region         = "eu-central-1"
		dynamodb_table = "gym-tracker-terraform-locks"
		encrypt        = true
		# If you prefer S3 lockfile locking over DynamoDB, remove dynamodb_table and set use_lockfile = true.
	}
}
