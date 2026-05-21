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
                withCredentials([sshUserPrivateKey(credentialsId: 'my-aws-key', keyFileVariable: 'KEY_FILE')]) {
                    sh '''
                    echo "Waiting 60 seconds for EC2 instances to fully boot..."
                    sleep 60
                    
                    # استخراج الـ IP بتاع الـ Bastion
                    BASTION_IP=$(terraform output -raw bastion_public_ip)
                    
                    echo "Creating custom SSH config to bypass all shell escaping issues..."
                    # إنشاء ملف إعدادات SSH مخصص
                    cat <<EOF > ssh_config
                    Host bastion
                        HostName $BASTION_IP
                        User ubuntu
                        IdentityFile $KEY_FILE
                        StrictHostKeyChecking no
                        UserKnownHostsFile /dev/null

                    Host 10.1.*
                        User ubuntu
                        IdentityFile $KEY_FILE
                        ProxyCommand ssh -F ssh_config bastion -W %h:%p
                        StrictHostKeyChecking no
                        UserKnownHostsFile /dev/null
                    EOF

                    echo "Starting Ansible Deployment using isolated SSH config..."
                    
                    # إجبار Ansible على استخدام ملف الـ SSH اللي لسه عاملينه
                    export ANSIBLE_SSH_ARGS="-F ssh_config"
                    
                    # أمر Ansible بقى بسيط ونظيف جداً
                    ansible-playbook -i inventory.ini deploy_app.yml -vvvv
                    '''
                }
            }
        }
}

}
