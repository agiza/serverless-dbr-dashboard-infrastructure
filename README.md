# DBR Infrastructure

This component exist to manage all infrastructure resources related to DBR Lambda

**Note:** Resources here are mono-environment.

## Resources

- IAM Roles
- IAM Policies
- Lambda
- DynamoDB Table
- Athena Database
- Athena Table
- S3 Bucket

## Setup

**Terraform is required, must be installed, and credentials for the
AWS account must be setup before continuing.**

Setup the DBR module

```
module "dbr" {
  source = "github.comfull360/DBR"

  region                          = "${var.region}"
  billing_aws_reports_bucket_name = "bucket-name-where-report-files-are"
}

```

We recommend to follow the directory structure on `example-region-name`

```    ├── example-region-name
    │   └── _shared
    │       └── dbr
    │           ├── env
    │           │   └── prod.tfvars
    │           ├── main.tf
    │           │   └── prod
    │           └── variables.tf
```
- Create the module following the schema in `example-region-name/_shared/dbr/main.tf.sample`

- Create a directory inside `terraform` folder, use the name of the region where DBR will run, example `us_west`

- Inside `us_west` create `_shared/dbr` directories and copy the main and the variables

```
cp terraform/example-region-name/_shared/dbr/main.tf.sample terraform/us_west/_shared/dbr/main.tf && cp terraform/example-region-name/_shared/dbr/env/prod.tfvars.sample terraform/us_west/_shared/dbr/env/prod.tfvars && cp terraform/example-region-name/_shared/dbr/variables.tf.sample terraform/us_west/_shared/dbr/variables.tf
```

Use the correct credentials **please**. Export the `AWS_PROFILE` or append it to
every command:

    export AWS_PROFILE=aws_profile

or:

    AWS_PROFILE=aws_profile terraform workspace list

Once terraform is in place and ready to use we can `init` our directory:

Initializing:

    terraform init

Now that we have our terraform initialized we are ready to continue an plan our infrastructure.

    terraform plan

The output of this should say that there are **Plan: 29 to add, 0 to change, 0 to destroy.** to apply. If that's
the case you are done.

Now you are ready to apply them (remember to always plan fist) use the following command:

    terraform apply

In case you follow the example inside `example-region-name` you will need to add the parameter `-var-file=env/prod.tfvars` to the plan and apply commands, i.e `terraform plan -var-file=env/prod.tfvars`

