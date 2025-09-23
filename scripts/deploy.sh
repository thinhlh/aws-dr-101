#!/bin/bash

# AWS DR POC Deployment Script
# This script deploys the AWS Windows EC2 with DRS infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check completed."
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Validate configuration
    terraform validate
    
    # Format configuration
    terraform fmt
    
    cd ..
    
    print_success "Terraform configuration validated."
}

# Function to plan deployment
plan_deployment() {
    print_status "Planning Terraform deployment..."
    
    cd terraform
    
    # Create terraform plan
    terraform plan -out=tfplan
    
    cd ..
    
    print_success "Terraform plan created. Review the plan before applying."
}

# Function to apply deployment
apply_deployment() {
    print_status "Applying Terraform deployment..."
    
    cd terraform
    
    # Apply terraform plan
    terraform apply tfplan
    
    cd ..
    
    print_success "Infrastructure deployed successfully!"
}

# Function to show outputs
show_outputs() {
    print_status "Deployment outputs:"
    
    cd terraform
    terraform output
    cd ..
}

# Function to create terraform.tfvars if it doesn't exist
setup_tfvars() {
    if [ ! -f "terraform/terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform/terraform.tfvars.example terraform/terraform.tfvars
        print_warning "Please edit terraform/terraform.tfvars with your specific values before continuing."
        print_warning "Especially important: Set your key_pair_name and restrict allowed_cidr_blocks for security."
        read -p "Press Enter to continue after editing terraform.tfvars..."
    fi
}

# Function to display help
show_help() {
    echo "AWS DR POC Deployment Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  plan     - Plan the deployment (terraform plan)"
    echo "  apply    - Apply the deployment (terraform apply)"
    echo "  destroy  - Destroy the deployment (terraform destroy)"
    echo "  output   - Show deployment outputs"
    echo "  full     - Run full deployment (plan + apply)"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 plan      # Plan the deployment"
    echo "  $0 full      # Run complete deployment"
    echo "  $0 destroy   # Destroy all resources"
}

# Main script logic
main() {
    case "${1:-help}" in
        "plan")
            check_prerequisites
            setup_tfvars
            validate_terraform
            plan_deployment
            ;;
        "apply")
            check_prerequisites
            cd terraform
            terraform apply
            cd ..
            show_outputs
            ;;
        "destroy")
            print_warning "This will destroy all AWS resources created by this project!"
            read -p "Are you sure? Type 'yes' to continue: " confirm
            if [ "$confirm" = "yes" ]; then
                cd terraform
                terraform destroy
                cd ..
                print_success "Resources destroyed."
            else
                print_status "Destruction cancelled."
            fi
            ;;
        "output")
            show_outputs
            ;;
        "full")
            check_prerequisites
            setup_tfvars
            validate_terraform
            plan_deployment
            echo ""
            print_warning "Review the plan above. Do you want to proceed with deployment?"
            read -p "Type 'yes' to apply: " confirm
            if [ "$confirm" = "yes" ]; then
                apply_deployment
                show_outputs
                print_success "Deployment completed! Check the outputs above for access information."
            else
                print_status "Deployment cancelled."
            fi
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"