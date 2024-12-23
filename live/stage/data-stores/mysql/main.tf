provider "aws" {
    region = "eu-central-1"
    alias = "primary"
}
provider "aws" {
    region = "eu-north-1"
    alias = "replica"
}

module "mysql_primary" {
    source = "../../../../modules/data-stores/mysql"
    providers = {
        aws = aws.primary
    }
    allocated_storage = 10
    db_name = "stage_db"
    db_username = var.db_username
    db_password = var.db_password
    # Must be enabled to support replication
    backup_retention_period = 1
}

module "mysql_replica" {
    source = "../../../../modules/data-stores/mysql"
    providers = {
        aws = aws.replica
    }
    # Make this a replica of the primary
    replicate_source_db = module.mysql_primary.arn
}
