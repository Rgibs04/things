@echo off
REM ClassDojo Debit System - Kubernetes Deployment Script for Windows
REM This script automates the deployment process

setlocal enabledelayedexpansion

set IMAGE_NAME=classdojo-debit-system
set IMAGE_TAG=latest
set NAMESPACE=classdojo-system

echo ========================================
echo ClassDojo Debit System - K8s Deployment
echo ========================================
echo.

REM Check prerequisites
echo Checking prerequisites...

where kubectl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: kubectl is not installed
    exit /b 1
)

where docker >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: docker is not installed
    exit /b 1
)

echo [OK] Prerequisites check passed
echo.

REM Build Docker image
echo Building Docker image...
cd ..
docker build -t %IMAGE_NAME%:%IMAGE_TAG% .
if %ERRORLEVEL% NEQ 0 (
    echo Error: Docker build failed
    exit /b 1
)
echo [OK] Docker image built successfully
echo.

REM Check if using minikube
where minikube >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    minikube status >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo Detected minikube, loading image...
        minikube image load %IMAGE_NAME%:%IMAGE_TAG%
        echo [OK] Image loaded to minikube
        echo.
    )
)

REM Deploy to Kubernetes
echo Deploying to Kubernetes...
cd k8s

kubectl apply -f namespace.yaml
echo [OK] Namespace created

kubectl apply -f configmap.yaml
echo [OK] ConfigMap created

kubectl apply -f secret.yaml
echo [OK] Secret created

kubectl apply -f persistent-volume.yaml
echo [OK] PersistentVolume created

kubectl apply -f persistent-volume-claim.yaml
echo [OK] PersistentVolumeClaim created

kubectl apply -f deployment.yaml
echo [OK] Deployment created

kubectl apply -f service.yaml
echo [OK] Service created

echo.
echo Waiting for deployment to be ready...
kubectl wait --for=condition=available --timeout=300s deployment/classdojo-debit-system -n %NAMESPACE%
echo [OK] Deployment is ready
echo.

REM Display status
echo ========================================
echo Deployment Status
echo ========================================
echo.

echo Pods:
kubectl get pods -n %NAMESPACE%
echo.

echo Services:
kubectl get svc -n %NAMESPACE%
echo.

REM Get access information
echo ========================================
echo Access Information
echo ========================================
echo.

where minikube >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    minikube status >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo To access the application, run:
        echo   minikube service classdojo-service -n %NAMESPACE%
        goto :end
    )
)

echo To access the application, run:
echo   kubectl port-forward -n %NAMESPACE% svc/classdojo-service 5000:80
echo   Then access: http://localhost:5000

:end
echo.
echo ========================================
echo Deployment completed successfully!
echo ========================================

endlocal
