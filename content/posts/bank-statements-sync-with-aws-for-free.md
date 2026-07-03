+++
title = "How I sync email bank statements with AWS for Free"
date = 2024-04-16T02:46:12-05:00
draft = true
tags = ["aws", "free", "freetier", "terraform", "lambda", "dynamodb"]
+++

{{< katex >}}

There is a way to get a cron job inside AWS that runs every few minutes and can store data up to 25GB, all for free. Here is how I did it.

## Problem

{{< alert "circle-info" >}}
If you just want the solution, feel free to [skip](#solution) this section.
{{< /alert >}}

I'm a person that likes to keep everything accounted for, I want to keep every aspect of my personal finances under control, but I don't want to become mad doing it, or invest insane amounts of hours keeping it in order. Fortunately, there are solutions to make this job easier, one such tool that I use is [Toshl](https://toshl.com): a personal finance app.

I am not advertising for this tool as being better than others, but this one has something that the majority (if not all) of the other ones I've looked into do not have: a public API (that is also documented).

This also works perfectly if you want to just use Google Spreadsheets, as you would just need to integrate with Google's API and log everything into a spreadsheet. You could even avoid any access to a different database, as it can serve you pretty much like one.

Why is this so important? **A: Automation, automation, AUTOMATION !!!**

The reason I want this is to be able to register new expenses, incomes, etc, into my app automatically from my bank statements. Now, you may be thinking that this is mostly solved already by most personal finance apps... and you would be right, except that this requires two things:

1. The bank has a public/private API that serves this information
2. Your app has an integration with that bank you want to use

ToshL charges for a special suscription (Medici plan), which lets you pull bank records into you account and current balance. But all banks from Colombia (my current location), do not have any of these features. ~~So? No luck to you!~~ Recently, I discovered that there is one service that lets you get this information called [Yoint](https://yoint.co), though for a price, and only specific to Colombia, so the solution laid out here still stands cheaper.

Fortunately, we can leverage from different aspects depending on each bank, my main use case was with [Bancolombia](https://www.bancolombia.com), in which for each transaction that gets conducted on the platform it sends a notification email for each.

Ok, so we now have a source of the information in place, and the destination is our finance app. Now what we want is to have a way to execute this for free, and without configuring a mini computer in you basement (like a Raspberry Pi) that executes this every few minutes, especially for the fact that not everyone has a spare computer at home that is working 24/7 without downtime.

## Solution

Fortunately for us, Amazon Web Services offers some of its services for free, for an undefined amount of time, as long as you don't get over the specified quota for each of the services that you are going to use.

### AWS Free Tier

In particular for our use case, we are interested in:

**AWS Lambda**
- 1,000,000 free requests per month
- Up to 3.2 million seconds of compute time per month

Let's say that we want to check our email every \\( n \\) minutes, assuming the worst case in which we want \\( n = 1 \\), that would give us only 43,200 requests per month.

**DynamoDB**
- 25 GB of Storage
- 25 provisioned Write Capacity Units (WCU)
- 25 provisioned Read Capacity Units (RCU)
- Enough to handle up to 200M requests per month.

We also want to know what emails have been processed, for this we need a database that stores our data. We can go with multiple approaches to handle this, the most trivial one would be to store every email ID into a DynamoDB table so that we know which messages have been processed, sure, it works, but is always increasing (unless you do housekeeping with the application to remove old ones). Either way, 25GB in storage is more than enough for our use case.

I will explain the actual approach I took afterwards.

### Terraform

Terraform is a great tool to put our infrastructure in a declarative language, I used it as a manner to keep all the infrastructure easily replicable, even if anything gets misconfigured by accident, we can always go back to a previous version since everything is kept in a version control system.

### Architecture

The different services that we need for this to work at AWS, is:
- Lambda function
- Cloudwatch Rule: to fire the Lambda function every \\( n \\) minutes
- DynamoDB table

{{< mermaid >}}
---
title: Architecture
---
%%{init: {'theme':'dark'}}%%
flowchart LR
    dynamo[("DynamoDB \n table")]
    lambda["Lambda function"]
    cloudwatch["CloudWatch \n every 5 minutes"]

    subgraph external["External"]
      toshl["Toshl service"]
      email["Email service"]
    end

    subgraph AWS

	subgraph cloudwatch["CloudWatch"]
	  event_rule["Event rule \n every 5 min"]
	end

	subgraph IAM
	    lambda_role["Lambda role"]
	    dynamodb_role["DynamoDB role"]
	end

	event_rule --->|assumes|lambda_role
	lambda --->|assumes|dynamodb_role

        event_rule --->|fires|lambda
        lambda --->|read/write|dynamo
    end

    lambda --->|reads|email
    lambda --->|writes|toshl
{{< /mermaid >}}
