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
ARG MAVEN_VERSION=3.6.0
ARG USER_HOME_DIR="/root"
ARG SHA=fae9c12b570c3ba18116a4e26ea524b29f7279c17cbaadc3326ca72927368924d9131d11b9e851b8dc9162228b6fdea955446be41207a5cfc61283dd8a561d2f
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

VOLUME /var/jenkins_home
VOLUME ${MAVEN_CONFIG}

# Stay as root for custom entrypoint, which will then switch back to jenkins user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/bin/sh", "/usr/local/bin/entrypoint.sh"]
