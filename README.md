# jenkins

[![Docker Automated build](https://img.shields.io/docker/build/fixiu/jenkins-pipeline.svg)](https://hub.docker.com/r/fixiu/jenkins-pipeline/builds/)

> WARNING
>
> If you run this container with the host's docker socket bind mounted then you are granting Jenkins, everyone with access to Jenkins, and all code executed under Jenkins, root access to that host (since any of these could start a container with such access).
>
> Consider carefully where you run this and what other mitigating controls you put in place, certainly, this has no place in a production environment. If you don't understand this warning you shouldn't run this image!

Jenkins with the Docker tools, BlueOcean and other useful plugins, Rancher CLI, all installed by default.

Built on top of jenkins/jenkins:lts-alpine. Full plugin list is in plugins.txt

## Build locally

```
$ cd docker-jenkins
$ docker build -t fixiu/jenkins-pipeline .
```

## Run (will pull from dockerhub)

```
$ mkdir /home/jenkins_home
$ chown -R 1000:1000 /home/jenkins_home
$ docker run -it -d -p 8080:8080 --privileged -v /home/jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock fixiu/jenkins-pipeline
```
