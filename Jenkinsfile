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
            # 1. فتح نفق SSH في الخلفية للـ App Server
            ssh -f -N -o StrictHostKeyChecking=no -o ProxyJump=ubuntu@${module.compute.bastion_public_ip} -L 2222:${module.compute.application_private_ip}:22 ubuntu@${module.compute.bastion_public_ip}
            
            # 2. الآن Ansible سيتصل بالـ Localhost على بورت 2222
            # هذا البورت هو "باب" ينقل البيانات مباشرة للـ App Server
            ansible-playbook -i localhost, -e "ansible_ssh_host=127.0.0.1 ansible_ssh_port=2222 ansible_user=ubuntu" deploy_app.yml -vvvv
            """
        }
    }
}
}

}
