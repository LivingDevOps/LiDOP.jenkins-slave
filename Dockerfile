FROM alpine

# Needed Software
RUN apk update \
    && apk add --no-cache  \
		sudo  \
		bash \
		nodejs \
		unzip  \
		openssh \
		openjdk8 \
		git \
		subversion \
		curl \
		wget \
		python \
		py-pip \
		ansible \
		nss \
		terraform

RUN pip3 install --upgrade pip  \
	&& pip3 install \
		docker  \
		docker-compose  \
		pywinrm

# Jenkins User and slave
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG VERSION=3.9
ARG JENKINS_AGENT_HOME=/home/${user}
ARG AGENT_WORKDIR=/home/${user}/agent

RUN addgroup -g ${gid} ${group} \
	&& adduser -D -h "${JENKINS_AGENT_HOME}" -u "${uid}" -G "${group}" -s /bin/bash "${user}" \
	&& passwd -u jenkins

RUN curl --create-dirs -fsSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

USER root

# Sonar Runner
WORKDIR /sonar

ENV SONAR_RUNNER_HOME=/sonar/sonar-scanner
ENV PATH $PATH:/sonar/sonar-scanner/bin
ENV SONAR_SERVER =localhost
ENV SECRET_PASSWORD=undef
ENV SONAR_SCANNER_OPTS="-Xmx512m"

RUN curl --insecure -o /tmp/sonarscanner.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip  \
  	&& unzip /tmp/sonarscanner.zip \
	&& rm /tmp/sonarscanner.zip \
	&& mv ./sonar-scanner-3.3.0.1492-linux ./sonar-scanner

COPY sonar-runner.properties ./sonar-scanner/conf/sonar-scanner.properties
RUN sed -i 's/use_embedded_jre=true/use_embedded_jre=false/g' ./sonar-scanner/bin/sonar-scanner

# Cleanup 
RUN	rm -rf /var/cache/apk/*

# Git Config
RUN git config --system http.sslVerify false

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
