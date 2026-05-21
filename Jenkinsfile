pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Choose the environment')
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose terraform action')
    }

    environment {
        AWS_ACCESS_KEY_ID          = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY      = credentials('aws-secret-key')
        AWS_DEFAULT_REGION         = 'us-east-1'
        TF_REGISTRY_CLIENT_TIMEOUT = '300'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Select Workspace') {
            steps {
                sh "terraform workspace select ${params.ENVIRONMENT} || terraform workspace new ${params.ENVIRONMENT}"
            }
        }

        stage('Terraform Plan') {
            steps {
                sh "terraform plan -var-file=${params.ENVIRONMENT}.tfvars"
            }
        }

        stage('Terraform Action') {
            steps {
                sh "terraform ${params.ACTION} -var-file=${params.ENVIRONMENT}.tfvars -auto-approve"
            }
        }

stage('Deploy Application') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sshagent(['my-aws-key']) {
                    sh '''
                    echo "Waiting 60 seconds for EC2 instances to fully boot..."
                    sleep 60
                    
                    
                    BASTION_IP=$(terraform output -raw bastion_public_ip)
                    
                   
                    KEY_PATH=$(find /var/jenkins_home/workspace/Terraform-Infra@tmp -name "private_key_*.key" | head -n 1)
                    
                    echo "Starting Ansible Deployment using exact Key File..."
                    
                    
                    ansible-playbook -i inventory.ini deploy_app.yml \
                        --private-key "$KEY_PATH" \
                        --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand=\"ssh -i $KEY_PATH -W %h:%p -q ubuntu@$BASTION_IP -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\"" \
                        -vvvv
                    '''
                }
            }
        }
}

}
