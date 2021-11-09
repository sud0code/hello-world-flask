# Deploying FLASK application to AWS ECS (Fargate)

This document will go through the steps and tools required to setup a python flask application in AWS Fargate with an application load balancer.

The system is setup in such a way that every update (push) in the source code would automatically update the hosted app as well.

### Application Code:

```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello World!!!"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
```



### Dockerfile:

```dockerfile
FROM python:slim-buster

COPY . /flask-app

WORKDIR /flask-app

RUN pip3 install -r requirements.txt

CMD ["python3","app.py"]

EXPOSE 80
```



### Tools / Services used:

1. Git / GitHub (Version Control and SCM)
2. Jenkins (Automation Server)
3. AWS CLI
4. Docker (Containerization)
5. AWS Elastic Container Registry
6. AWS Elastic Container Service
7. AWS Elastic Load Balancer
8. AWS Route 53 (DNS)



### Steps:

- Setup Git on your local machine and create a GitHub repository.
- Launch an EC2 instance to work as a Jenkins server.
- Install Docker, AWS CLI and Git in the same automation server.
- Create IAM roles specific to the task and set policies with access only to the relevant services.
- Configure AWS CLI with access keys of the concerned user created in the previous step
- Create a new pipeline task in Jenkins.
- The pipeline is setup in Jenkins into 5 stages: 
  1. Logging into AWS ECR
  2. Cloning GitHub repository
  3. Building Docker image
  4. Pushing image to ECR
  5. Updating ECS with updated image
- So according to the pipeline, setup a repository in ECR and get URI of the repo which will be used in the pipeline script.
- Setup Git-Hooks so that every 'PUSH' will act as a build trigger for the pipeline.
- Install docker plugin and write script to build it with relevant tag and  repo name.
- Use "docker push" with relevant credentials to push image into repository
- Use "update-service" command in AWS CLI to force new deployment with updated image.
- Create ECS Tasks (with the image present in ECR), Service and then Target groups and wrap it together and form a Application Load Balancer.
- Then setup hosted zones in Route 53 and pair custom domain and the load balancer.



### Pipeline Script:


```pipeline {
    agent any
    environment {
        AWS_ACCOUNT_ID="571370703756"
        AWS_DEFAULT_REGION="ap-south-1" 
        IMAGE_REPO_NAME="hello-world-flask"
        IMAGE_TAG="latest"
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}"
    }
   
    stages {
        stage('Logging into AWS ECR') {
            steps {
                script {
                sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                	}
            	}
        	}
         
        stage('Cloning Git') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/sud0code/hello-world-flask.git']]])     
            		}
        	}
  
    stage('Building image') {
      steps{
        script {
          dockerImage = docker.build "${IMAGE_REPO_NAME}:${IMAGE_TAG}"
        }
      }
    }
   
    stage('Pushing to ECR') {
     steps{  
         script {
                sh "docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:$IMAGE_TAG"
                sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"
         }
        }
      }
      
      stage('Updating ECS') {
            steps {
                script {
                sh "aws ecs update-service --cluster flaskcluster --service flask-service --force-new-deployment --region ap-south-1"
                }
                 
            }
        }
    }
}
```



### Further Considerations:

- Configuring SSL certificates to enable HTTPS connection.



**Project website:** [<u>test.flask-hello-world.ml</u>](http://test.flask-hello-world.ml/)

