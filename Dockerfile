FROM adoptopenjdk/openjdk11:alpine-jre

ARG JAR_FILE=target/calc.jar

WORKDIR /opt/app

COPY ${JAR_FILE} calc.jar

COPY entrypoint.sh entrypoint.sh

RUN chmod 755 entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]