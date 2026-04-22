# 🚀 VPC Flow Logs Analysis using AWS Athena

![AWS](https://img.shields.io/badge/AWS-Athena%20%7C%20S3%20%7C%20VPC-orange)
![Terraform](https://img.shields.io/badge/IaC-Terraform-blue)
![Status](https://img.shields.io/badge/Status-Completed-success)

---

## 📌 Overview
This project demonstrates how to build a **serverless log analytics pipeline** on AWS to analyze VPC Flow Logs.

Using Terraform, the infrastructure is fully automated to:
- Capture network traffic logs from a VPC  
- Store logs in Amazon S3  
- Query logs using Amazon Athena  

This enables efficient monitoring, troubleshooting, and security analysis of network traffic.

---

## 🏗️ Architecture
VPC Flow Logs
↓
Amazon S3 (Log Storage)
↓
AWS Glue (Data Catalog)
↓
Amazon Athena (SQL Queries)


---

## ⚙️ Tech Stack

- **Cloud**: AWS (VPC, S3, Athena, Glue)
- **IaC**: Terraform
- **Scripting**: Bash
- **Query Engine**: SQL (Athena)

---

## ✨ Features

- Infrastructure provisioning using Terraform  
- Centralized log storage in Amazon S3  
- Serverless querying with Athena  
- Scalable and cost-efficient architecture  
- Useful for network monitoring and security analysis  

---

## 📂 Project Structure

├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── userdata_public.sh
├── userdata_private.sh
├── .gitignore
└── README.md

