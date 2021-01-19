FROM golang:1.15.6-buster AS builder

# Get sql_exporter
ENV GOPATH=/go
RUN go get -d github.com/ibmdb/go_ibm_db
RUN cd /go/src/github.com/ibmdb/go_ibm_db/installer/ && go run setup.go
ADD .   /go/src/github.com/free/sql_exporter
WORKDIR /go/src/github.com/free/sql_exporter

# Do makefile
RUN apt-get update && apt-get install -y libxml2 && apt-get clean
RUN make build

# Make image and copy build sql_exporter
FROM        bitnami/minideb:latest

RUN apt-get update && apt-get install -y libxml2 && apt-get clean

ENV LD_LIBRARY_PATH=/bin/clidriver/lib
COPY        --from=builder /go/src/github.com/ibmdb/go_ibm_db/installer/clidriver/  /bin/clidriver/
COPY        --from=builder /go/src/github.com/free/sql_exporter/sql_exporter  /bin/sql_exporter

RUN mkdir /config

EXPOSE      9399
ENTRYPOINT  [ "/bin/sql_exporter","-config.file","/config/sql_exporter.yml" ]
