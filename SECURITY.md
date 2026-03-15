# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Please do NOT open a public GitHub issue for security vulnerabilities.**

Instead, send an email to: **kogunlowo@gmail.com**

Include the following details:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Suggested fix (if any)

You should receive a response within 48 hours acknowledging your report. We will work with you to understand and address the issue before any public disclosure.

## Security Best Practices

When using this Terraform module, please follow these security best practices:

- **State Management**: Store Terraform state in a secure backend (e.g., S3 with encryption and DynamoDB locking)
- **Secrets Management**: Never hardcode secrets in Terraform files. Use AWS Secrets Manager, SSM Parameter Store, or environment variables
- **IAM Least Privilege**: Use the minimum required permissions for all IAM roles and policies
- **Encryption**: Enable encryption at rest and in transit for all supported resources
- **Access Control**: Restrict access to Terraform state files and CI/CD pipelines
- **Version Pinning**: Pin provider and module versions to avoid unexpected changes
- **Code Review**: Require peer review for all infrastructure changes
- **Audit Logging**: Enable AWS CloudTrail and other audit logging mechanisms

## Supported Versions

We typically provide security updates for the latest major version only.
