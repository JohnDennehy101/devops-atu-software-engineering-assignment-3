###############################################################################
# Define project prefix to assign to resource names for easier identification #
###############################################################################

variable "prefix" {
  description = "Prefix for resources in AWS"
  default     = "devops-sw-3"
}

#######################
# Define project name #
#######################

variable "project" {
  description = "Project name"
  default     = "devops-sw-pipelines-assignment-3"
}

######################################################################################################################
# Define infra user contact details (which are tagged on resources - easier for other devs to contact if any issues) #
######################################################################################################################

variable "contact" {
  description = "Contact email for created resources (useful if team environment)"
  default     = "L00196611@atu.ie"
}

#############################################################################################
# Define variable that will store ECR repo url for API (loaded via GitHub actions variable) #
#############################################################################################

variable "ecr_api_image" {
  description = "ECR repo path that contains image with API"
}

##########################################################################################################
# Define variable that will store ECR repo url for Prometheus image (loaded via GitHub actions variable) #
##########################################################################################################

variable "ecr_prometheus_image" {
  description = "ECR repo path that contains image with Prometheus"
}

#######################################################################################################
# Define variable that will store ECR repo url for Grafana image (loaded via GitHub actions variable) #
#######################################################################################################

variable "ecr_grafana_image" {
  description = "ECR repo path that contains image with Grafana"
}

##################################################################################################
# Define variable that will store ECR repo url for frontend (loaded via GitHub actions variable) #
##################################################################################################

variable "ecr_frontend_image" {
  description = "ECR repo path that contains image with frontend"
}

#################################################
# Define custom domain name purchased on Route 53
#################################################

variable "dns_zone_name" {
  description = "domain name"
  default     = "iacmoduleassignmentdomain.click"
}

#######################################
# Define sub domain map per environment
#######################################

variable "subdomain" {
  description = "subdomain for different environments"
  type        = map(string)

  default = {
    prod    = "code"
    staging = "code.staging"
    dev     = "code.dev"
  }
}

####################
# Define db username
####################

variable "database_username" {
  description = "database username for notes database"
  default     = "notes_user"
}

################################################################
# Define db password (which will store the value passed to it) #
################################################################

variable "database_password" {
  description = "database password for notes database"
}
