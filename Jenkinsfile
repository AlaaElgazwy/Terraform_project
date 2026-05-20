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
            sh """
            echo "--- Testing Bastion Connection ---"
            ssh -vvv -o StrictHostKeyChecking=no ubuntu@${module.compute.bastion_public_ip} "echo Bastion Reachable"
            
            echo "--- Testing App EC2 Connection ---"
            ssh -vvv -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q ubuntu@${module.compute.bastion_public_ip} -o StrictHostKeyChecking=no" ubuntu@${module.compute.application_private_ip} "echo App EC2 Reachable"
            
            echo "--- Running Ansible ---"
            ansible-playbook -i inventory.ini deploy_app.yml -vvv
            """
        }
    }
}

}

}
