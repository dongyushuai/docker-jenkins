FROM jenkins/jenkins:lts-alpine

# Install plugins, if they aren't already
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Suppress plugin install banner
RUN echo 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

# Installing packages, need to be root to do so
USER root

# We need docker tools, make and ssl support for wget
ENV PACKAGES "gcc ca-certificates docker make openssl nodejs nodejs-npm"
RUN apk add --update $PACKAGES \
#    && cp -r -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && rm -rf /var/cache/apk/*

# Download and install Rancher CLI
ENV RANCHER_CLI_VERSION 0.6.11
# The rancher tar.gz includes permissions data for the "current" folder, so don't extract to the root of /tmp since it will change the permissions :-(
RUN mkdir /tmp/rancher \
  && wget -qO- https://github.com/rancher/cli/releases/download/v${RANCHER_CLI_VERSION}/rancher-linux-amd64-v${RANCHER_CLI_VERSION}.tar.gz \
  | tar xvz -C /tmp/rancher \
  && mv /tmp/rancher/rancher-v${RANCHER_CLI_VERSION}/rancher /usr/local/bin/rancher \
  && chmod +x /usr/local/bin/rancher \
  && rm -r /tmp/rancher

# Download and install Rancher Compose
ENV RANCHER_COMPOSE_VERSION 0.12.5
# The rancher tar.gz includes permissions data for the "current" folder, so don't extract to the root of /tmp since it will change the permissions :-(
RUN mkdir /tmp/rancher-compose \
  && wget -qO- https://github.com/rancher/rancher-compose/releases/download/v${RANCHER_COMPOSE_VERSION}/rancher-compose-linux-amd64-v${RANCHER_COMPOSE_VERSION}.tar.gz \
  | tar xvz -C /tmp/rancher-compose \
  && mv /tmp/rancher-compose/rancher-compose-v${RANCHER_COMPOSE_VERSION}/rancher-compose /usr/local/bin/rancher-compose \
  && chmod +x /usr/local/bin/rancher-compose \
  && rm -r /tmp/rancher-compose
  
# Install Maven
ARG MAVEN_VERSION=3.6.3
ARG USER_HOME_DIR="/root"
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG BASE_URL=https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# Install Sonar
ENV SONAR_RUNNER_VERSION 4.4.0.2170
ENV SONAR_RUNNER_HOME /usr/local/sonar-scanner-cli

RUN mkdir -p /tmp/sonar-scanner ${SONAR_RUNNER_HOME} \
	curl -fsSL -o /tmp/sonar-scanner-cli-${SONAR_RUNNER_VERSION}-linux.zip https://repo1.maven.org/maven2/org/sonarsource/scanner/cli/sonar-scanner-cli/${SONAR_RUNNER_VERSION}/sonar-scanner-cli-${SONAR_RUNNER_VERSION}-linux.zip \
	&& unzip -d /tmp/sonar-scanner sonar-scanner-cli-${SONAR_RUNNER_VERSION}-linux.zip \
	&& mv /tmp/sonar-scanner/sonar-scanner-cli-${SONAR_RUNNER_VERSION}-linux/* ${SONAR_RUNNER_HOME} \
	&& rm -f /tmp/sonar-scanner-cli-${SONAR_RUNNER_VERSION}-linux.zip

VOLUME /var/jenkins_home
VOLUME ${MAVEN_CONFIG}

# Stay as root for custom entrypoint, which will then switch back to jenkins user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
