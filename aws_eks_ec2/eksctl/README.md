## [aws cli](https://aws.amazon.com/cli/) & [eksctl](https://eksctl.io/)


```
aws sts get-caller-identity --query "Account" --output text
```

---------------------------------------

```
aws ecr create-repository --repository-name flask-app --region eu-central-1


aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.eu-central-1.amazonaws.com


docker build -t flask-app ../../app/


docker tag flask-app:latest <account>.dkr.ecr.eu-central-1.amazonaws.com/flask-app:v1


docker push <account>.dkr.ecr.eu-central-1.amazonaws.com/flask-app:v1
```

---------------------------------------

```
eksctl create cluster --name=eks-cluster-exp --nodegroup-name=eks-node-group-exp --nodes=1 --instance-types=t3.medium --region=eu-central-1
```

```
eksctl delete cluster --name=eks-cluster-exp --region=eu-central-1
```

---------------------------------------

```
kubectl create -f service.yaml

kubectl create -f deployment.yaml
```

```
kubectl delete -f service.yaml

kubectl delete -f deployment.yaml
```

