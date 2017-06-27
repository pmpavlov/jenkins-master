FROM jenkins:alpine
MAINTAINER Pavlov <ppavlov@dontmail.me>

LABEL name="jenkins-master"
LABEL version="1.0"
LABEL maintainer "ppavlov@dontmail.me"
LABEL architecture="x86_64"

COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

EXPOSE 8080 
EXPOSE 50000
