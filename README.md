# Build Status [![Codefresh build status]( https://g.codefresh.io/api/badges/build?repoOwner=pmpavlov&repoName=jenkins-master&branch=master&pipelineName=jenkins-master&accountName=ppavlov&type=cf-1)]( https://g.codefresh.io/repositories/pmpavlov/jenkins-master/builds?filter=trigger:build;branch:master;service:58eb8c8530fa280100c9fba7~jenkins-master)

# CirclCI [![CircleCI build status] !https://circleci.com/gh/pmpavlov/jenkins-master.svg?style=svg!:https://circleci.com/gh/pmpavlov/jenkins-master

# How to use this image

   docker run -p 8080:8080 -p 50000:50000 ppavlov/jenkins-master

This will store the workspace in /var/jenkins_home. All Jenkins data lives in there - including plugins and configuration. You will probably want to make that a persistent volume (recommended):

   docker run -p 8080:8080 -p 50000:50000 -v /your/home:/var/jenkins_home ppavlov/jenkins-master

This will store the jenkins data in /your/home on the host. Ensure that /your/home is accessible by the jenkins user in container (jenkins user - uid 1000) or use -u some_other_user parameter with docker run.

You can also use a volume container:

   docker run --name myjenkins -p 8080:8080 -p 50000:50000 -v /var/jenkins_home ppavlov/jenkins-master

Then myjenkins container has the volume (please do read about docker volume handling to find out more).

# Backing up data

If you bind mount in a volume - you can simply back up that directory (which is jenkins_home) at any time.
This is highly recommended. Treat the jenkins_home directory as you would a database - in Docker you would generally put a database on a volume.

If your volume is inside a container - you can use docker cp $ID:/var/jenkins_home command to extract the data, or other options to find where the volume data is. Note that some symlinks on some OSes may be converted to copies (this can confuse jenkins with lastStableBuild links etc)

For more info check Docker docs section on [`Managing data in containers`](https://docs.docker.com/engine/tutorials/dockervolumes/)

# Setting the number of executors
You can specify and set the number of executors of your Jenkins master instance using a groovy script. By default its set to 2 executors, but you can extend the image and change it to your desired number of executors :

executors.groovy

import jenkins.model.*
Jenkins.instance.setNumExecutors(5)
and Dockerfile

FROM ppavlov/jenkins-master
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

# Attaching build executors
You can run builds on the master (out of the box) but if you want to attach build slave servers: make sure you map the port: -p 50000:50000 - which will be used when you connect a slave agent.

# Passing JVM parameters
You might need to customize the JVM running Jenkins, typically to pass system properties or tweak heap memory settings. Use JAVA_OPTS environment variable for this purpose :

  docker run --name myjenkins -p 8080:8080 -p 50000:50000 --env JAVA_OPTS=-Dhudson.footerURL=http://mycompany.com ppavlov/jenkins-master

# Configuring logging
Jenkins logging can be configured through a properties file and java.util.logging.config.file Java property. For example:

mkdir data
cat > data/log.properties <<EOF
handlers=java.util.logging.ConsoleHandler
jenkins.level=FINEST
java.util.logging.ConsoleHandler.level=FINEST
EOF

   docker run --name myjenkins -p 8080:8080 -p 50000:50000 --env JAVA_OPTS=" Djava.util.logging.config.file=/var/jenkins_home/log.properties" -v `pwd`/data:/var/jenkins_home ppavlov/jenkins-master
   
You also can define jenkins arguments as JENKINS_OPTS. This is useful to define a set of arguments to pass to jenkins launcher as you define a derived jenkins image based on the official one with some customized settings. The following sample Dockerfile uses this option to force use of HTTPS with a certificate included in the image

FROM ppavlov/jenkins-master

COPY https.pem /var/lib/jenkins/cert
COPY https.key /var/lib/jenkins/pk
ENV JENKINS_OPTS --httpPort=-1 --httpsPort=8083 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk
EXPOSE 8083
You can also change the default slave agent port for jenkins by defining JENKINS_SLAVE_AGENT_PORT in a sample Dockerfile.

FROM ppavlov/jenkins-master
ENV JENKINS_SLAVE_AGENT_PORT 50001
or as a parameter to docker,

$ docker run --name myjenkins -p 8080:8080 -p 50001:50001 --env JENKINS_SLAVE_AGENT_PORT=50001 ppavlov/jenkins-master

# Installing more tools

You can run your container as root - and install via apt-get, install as part of build steps via jenkins tool installers, or you can create your own Dockerfile to customise, for example:

FROM ppavlov/jenkins-master
# if we want to install via apt
USER root
RUN apt-get update && apt-get install -y ruby make more-thing-here
USER jenkins # drop back to the regular jenkins user - good practice
In such a derived image, you can customize your jenkins instance with hook scripts or additional plugins. For this purpose, use /usr/share/jenkins/ref as a place to define the default JENKINS_HOME content you wish the target installation to look like :

FROM ppavlov/jenkins-master
COPY plugins.txt /usr/share/jenkins/ref/
COPY custom.groovy /usr/share/jenkins/ref/init.groovy.d/custom.groovy
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt
When jenkins container starts, it will check JENKINS_HOME has this reference content, and copy them there if required. It will not override such files, so if you upgraded some plugins from UI they won`t be reverted on next start.

Also see JENKINS-24986

For your convenience, you also can use a plain text file to define plugins to be installed (using core-support plugin format). All plugins need to be listed as there is no transitive dependency resolution.

pluginID:version
credentials:1.18
maven-plugin:2.7.1
...
And in derived Dockerfile just invoke the utility plugin.sh script

FROM ppavlov/jenkins-master
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt

