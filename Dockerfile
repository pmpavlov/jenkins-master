FROM jenkins:alpine

MAINTAINER P Pavlov <ppavlov@dontmail.me>

COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

EXPOSE 8080 
EXPOSE 50000
