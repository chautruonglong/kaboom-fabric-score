FROM openjdk:17-jdk-alpine3.14
ENV NAME=service-blockchain
ENV PORT=8009

WORKDIR /${NAME}/
COPY ./target/${NAME}*exec.jar ./${NAME}.jar

EXPOSE ${PORT}
ENTRYPOINT java -jar ${NAME}.jar
