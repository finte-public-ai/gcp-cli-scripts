# gcp-cli-scripts
Collection of CLI scripts to interact with GCP

## create_finte_readonly_role

Creates a custom FinteReadOnlyRole with necessary permissions at the organization level. Note, it needs to use the IAM API at the project level, which is why a Project ID is required. If the IAM API is not enabled, the script will enable it for you assuming the user that is running the script has appropriate permissions.

### Requirements
  * Enable the [Identity and Access Management (IAM) API](https://console.developers.google.com/apis/api/iam.googleapis.com/overview) in your project
  * GCP Organization ID
  * GCP Project ID (the script will automatically enable the IAM API if needed)

#### Required Permissions
The user running this script needs the following permissions:

**At the Project level:**
- `serviceusage.services.enable` - To enable the IAM API
- `serviceusage.services.list` - To check if IAM API is enabled
- `resourcemanager.projects.get` - To validate project access

**At the Organization level:**
- `iam.roles.create` - To create the custom role
- `iam.roles.get` - To describe the created role
- `resourcemanager.organizations.get` - To validate organization access

**Recommended roles that include these permissions:**
- Project level: `roles/serviceusage.serviceUsageAdmin` or `roles/editor`
- Organization level: `roles/iam.organizationRoleAdmin` or `roles/resourcemanager.organizationAdmin`

### Usage
```bash
./create_finte_readonly_role.sh --organization YOUR_ORG_ID --project YOUR_PROJECT_ID
```

### Parameters
- `--organization` or `-o`: GCP Organization ID (required)
- `--project` or `-p`: GCP Project ID (required) - The IAM API must be enabled in this project
- `--help` or `-h`: Show help message

### Example
```bash
./create_finte_readonly_role.sh --organization 123456789012 --project my-project-id
```
