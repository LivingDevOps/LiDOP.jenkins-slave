FROM alpine

ARG VERSION=3.9
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}

RUN addgroup -g ${gid} ${group} \
	&& adduser -D -h "${JENKINS_AGENT_HOME}" -u "${uid}" -G "${group}" -s /bin/bash "${user}" \
	&& passwd -u jenkins

RUN apk update \
    && apk add --no-cache sudo bash openssh openjdk8 git subversion curl wget python py-pip ansible nss terraform

ARG AGENT_WORKDIR=/home/${user}/agent

RUN curl --create-dirs -fsSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

RUN curl --insecure -o ./sonarscanner.zip -L https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip && \
	unzip sonarscanner.zip && \
	rm sonarscanner.zip && \
	mv sonar-scanner-3.3.0.1492-linux /usr/lib/sonar-scanner && \
	ln -s /usr/lib/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner

ENV SONAR_RUNNER_HOME=/usr/lib/sonar-scanner

COPY sonar-runner.properties /usr/lib/sonar-scanner/conf/sonar-scanner.properties

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

USER root
RUN pip3 install --upgrade pip
RUN pip3 install docker && pip3 install docker-compose && pip3 install pywinrm

RUN git config --system http.sslVerify false

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
