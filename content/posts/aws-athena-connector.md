+++
title = "AWS Athena Connector"
date = 2024-12-29T01:12:51-05:00
author = "Alejandro Anzola-Ávila"
authorTwitter = "aanzolaavila" #do not include @
cover = ""
tags = []
keywords = ["java", "terraform", "aws", "athena", "connector"]
description = ""
showFullContent = false
readingTime = true
hideComments = true
draft = true
+++

{{< katex >}}

Recently at work I stumbled on a way to implement a data connector to an external source of information from Athena pretty much like adding a table into a SQL database. While much of the content that can be found inside of AWS documentation explains and even shows tutorials on how to implement this from a 'dummy' POV, it does not show (or at least it is hard to find) how to do it from the ground up, and not rely on CloudFormation specs, or even depend on AWS Serverless images <TODO: what is the actual name of that?>.

While this solution can come out of the box based on the CloudFormation spec to deploy the Athena connector and be 'straighforward', it definitely does not work when the company solution is being done with Infrastructure as Code, in particular with Terraform.

My task was to create this connector automatically and give off all the configuration needed so that a new Data Source was available within Athena.

# Background

First off, if in doubt on what AWS Athena is, or what a connector is, you can consult each inside official AWS docs [here](link to docs).

Albeit, do give a tldr definition for it: Athena offers a way to do SQL queries on data sources that have different technologies, joining each one's data to then give a query result. Each data source is not required to be a relational database, but since the Athena engine works with that abstraction in mind, for each data source there must be a data connector that translates the original structure from the data source into a relational-like result with concepts like tables, rows, etc.

Now, usually what happens is that there is one or more main data sources that Athena sees by default to do queries, from which a query would usually derive the main records to then join with external data sources, one example of that is to store information in an S3 bucket within a folder that stores information as Parquet files. These can also be modified with a SQL sentence like `INSERT`, `UPDATE`, or `DELETE`.

A likely architecture for this use case looks like the following:

{{< mermaid >}}
---
title: Example Athena Architecture
---
architecture-beta
  group vpc(logos:aws-vpc)[VPC]
  group psubnet[Private Subnet] in vpc

  service athena(logos:aws-athena)[Athena] in vpc
  service server(server)[Server] in vpc
  service storage(logos:aws-s3)[Storage] in vpc
  service database(logos:aws-rds)[RDS Postgres] in psubnet
  service dbconnector(logos:aws-lambda)[Postgres Athena connector] in psubnet
  service externalconnector(logos-aws-lambda)[Custom Athena connector] in vpc

  athena:R -- L:dbconnector

{{< /mermaid >}}
