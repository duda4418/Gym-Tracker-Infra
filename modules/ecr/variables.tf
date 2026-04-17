variable "repository_names" {
  description = "ECR repositories to create."
  type        = list(string)
  default = [
    "gym-tracker-frontend",
    "gym-tracker-backend"
  ]
}

variable "image_tag_mutability" {
  description = "Image tag mutability mode."
  type        = string
  default     = "MUTABLE"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
