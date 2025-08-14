#!/bin/bash

# GCP FinteReadOnlyRole Creation Script
# This script creates a custom read-only role for Finte services

set -e  # Exit on any error

# Configuration
ROLE_ID="FinteReadOnlyRole"
ROLE_TITLE="FinteReadOnlyRole"
ROLE_DESCRIPTION="Custom read-only role for Finte Test services with specific permissions"
STAGE="GA"  # GA, BETA, ALPHA, or DISABLED

# Default values
ORGANIZATION_ID=""
PROJECT_ID=""
SCOPE="organization"  # This role is specifically for organization level

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -o, --organization ORG_ID       GCP Organization ID (required)"
    echo "  -p, --project PROJECT_ID        GCP Project ID (required)"
    echo "  -h, --help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --organization 123456789012 --project my-project-id"
    echo ""
    echo "Note: The IAM API must be enabled in the specified project."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--organization)
            ORGANIZATION_ID="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validation
if [[ -z "$ORGANIZATION_ID" ]]; then
    print_error "Organization ID is required"
    show_usage
    exit 1
fi

if [[ -z "$PROJECT_ID" ]]; then
    print_error "Project ID is required"
    show_usage
    exit 1
fi

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
    print_error "No active gcloud authentication found. Please run 'gcloud auth login'"
    exit 1
fi

# Validate project exists and set as current project
print_info "Validating project: $PROJECT_ID"
if ! gcloud projects describe "$PROJECT_ID" --format="value(projectId)" &> /dev/null; then
    print_error "Project '$PROJECT_ID' not found or you don't have access to it"
    exit 1
fi

# Set the project as current
print_info "Setting project context to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# Check if IAM API is enabled
print_info "Checking if IAM API is enabled in project: $PROJECT_ID"
if ! gcloud services list --enabled --filter="name:iam.googleapis.com" --format="value(name)" | grep -q "iam.googleapis.com"; then
    print_warning "IAM API is not enabled in project '$PROJECT_ID'"
    print_info "Enabling IAM API..."
    if gcloud services enable iam.googleapis.com; then
        print_success "IAM API enabled successfully"
    else
        print_error "Failed to enable IAM API. Please enable it manually:"
        echo "  gcloud services enable iam.googleapis.com --project=$PROJECT_ID"
        exit 1
    fi
else
    print_success "IAM API is already enabled"
fi

print_info "Creating role definition file..."

# Create temporary role definition file
ROLE_FILE=$(mktemp)
trap "rm -f $ROLE_FILE" EXIT

cat > "$ROLE_FILE" << EOF
title: "$ROLE_TITLE"
description: "$ROLE_DESCRIPTION"
stage: "$STAGE"
includedPermissions:
- cloudasset.assets.exportCloudresourcemanagerFolders
- cloudasset.assets.exportCloudresourcemanagerOrganizations
- cloudasset.assets.exportCloudresourcemanagerProjects
- cloudasset.assets.exportResource
- cloudasset.assets.listCloudresourcemanagerFolders
- cloudasset.assets.listCloudresourcemanagerOrganizations
- cloudasset.assets.listCloudresourcemanagerProjects
- cloudasset.assets.listResource
- cloudasset.assets.searchAllResources
- compute.commitments.get
- compute.commitments.list
- compute.regions.list
- monitoring.metricDescriptors.list
- monitoring.timeSeries.list
- resourcemanager.folders.get
- resourcemanager.folders.list
- resourcemanager.organizations.get
- resourcemanager.projects.get
- resourcemanager.projects.getIamPolicy
- resourcemanager.projects.list
EOF

print_info "Role definition created:"
cat "$ROLE_FILE"
echo ""

# Create the role at organization level
print_info "Creating custom role at organization level for organization: $ORGANIZATION_ID"

if gcloud iam roles create "$ROLE_ID" \
    --organization="$ORGANIZATION_ID" \
    --file="$ROLE_FILE" \
    --quiet; then
    print_success "Custom role '$ROLE_ID' created successfully in organization '$ORGANIZATION_ID'"
    
    # Display the created role
    print_info "Role details:"
    gcloud iam roles describe "$ROLE_ID" --organization="$ORGANIZATION_ID"
else
    print_error "Failed to create custom role"
    exit 1
fi

print_success "Script completed successfully!"
print_info "Role created at organization level using project context: $PROJECT_ID"
print_info "Note: The IAM API was enabled/verified in project: $PROJECT_ID"
print_info ""
print_info "You can now assign this role to users or service accounts using:"
echo "  gcloud organizations add-iam-policy-binding $ORGANIZATION_ID \\"
echo "    --member=\"user:email@domain.com\" \\"
echo "    --role=\"organizations/$ORGANIZATION_ID/roles/$ROLE_ID\""
echo ""
print_info "Or to assign to a service account:"
echo "  gcloud organizations add-iam-policy-binding $ORGANIZATION_ID \\"
echo "    --member=\"serviceAccount:service-account@project.iam.gserviceaccount.com\" \\"
echo "    --role=\"organizations/$ORGANIZATION_ID/roles/$ROLE_ID\""
