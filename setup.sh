#!/usr/bin/env bash
set -e

export DOCKER_USERNAME="yismaili"
export DOCKER_PASSWORD="pass1227@"
export DOCKER_REGISTRY="https://index.docker.io/v1/"

 docker login --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD" $DOCKER_REGISTRY
 docker logout

if [ ! "$( docker ps -q -f name=registry)" ]; then
     docker run -d -p 5000:5000 --restart=always --name registry registry:2
fi


docker build -t localhost:5000/pingpong-backend:latest .
docker push localhost:5000/pingpong-backend:latest

docker build -t localhost:5000/pingpong-frontend:latest .
docker push localhost:5000/pingpong-frontend:latest


kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Wait for the cluster to be ready
until sudo kubectl get nodes &> /dev/null; do
    echo "Waiting for the cluster to be ready..."
    sleep 5
done
# sleep 100
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d >> password.txt
kubectl port-forward svc/argocd-server -n argocd 8989:80 --address 0.0.0.0





kubectl apply -f namespace.yaml
kubectl apply -f postgres-pvc.yaml

kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml


kubectl apply -f postgres-deploment.yaml
kubectl apply -f postgres-service.yaml


kubectl apply -f backend-deploment.yaml
kubectl apply -f backend-service.yaml


kubectl apply -f frontend-deploment.yaml
kubectl apply -f frontend-service.yaml


kubectl apply -f adminer-deploment.yaml
kubectl apply -f adminer-service.yaml

kubectl apply -f ingress.yaml

kubectl get all -o wide -n pingpong

kubectl port-forward svc/frontend-service 3000:3000 -n pingpong --address 0.0.0.0


# delete
kubectl delete all --all -n pingpong
kubectl delete namespace pingpong


