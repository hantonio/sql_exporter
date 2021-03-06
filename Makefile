# Copyright 2015 The Prometheus Authors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GO     := go
GOPATH := $(firstword $(subst :, ,$(shell $(GO) env GOPATH)))
PROMU  := $(GOPATH)/bin/promu
pkgs    = $(shell $(GO) list ./... | grep -v /vendor/)

PREFIX              ?= $(shell pwd)
BIN_DIR             ?= $(shell pwd)
DOCKER_IMAGE_NAME   ?= sql-exporter
DOCKER_IMAGE_TAG    ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))

export DB2HOME=$(GOPATH)/src/github.com/ibmdb/go_ibm_db/installer/clidriver
export CGO_CFLAGS=-I$(DB2HOME)/include
export CGO_LDFLAGS=-L$(DB2HOME)/lib
export LD_LIBRARY_PATH=$(DB2HOME)/lib

all: format depend build test

style:
	@echo ">> checking code style"
	@! gofmt -d $(shell find . -path ./vendor -prune -o -name '*.go' -print) | grep '^'

test:
	@echo ">> running tests"
	@$(GO) test -short -race $(pkgs)

format:
	@echo ">> formatting code"
	@$(GO) fmt $(pkgs)

vet:
	@echo ">> vetting code"
	@$(GO) vet $(pkgs)

build: promu
	export DB2HOME=$(GOPATH)/src/github.com/ibmdb/go_ibm_db/installer/clidriver
	export CGO_CFLAGS=-I$(DB2HOME)/include
	export CGO_LDFLAGS=-L$(DB2HOME)/lib
	export LD_LIBRARY_PATH=$(DB2HOME)/lib
	@echo ">> building binaries"
	@$(PROMU) build --prefix $(PREFIX)

tarball: promu
	@echo ">> building release tarball"
	@$(PROMU) tarball --prefix $(PREFIX) $(BIN_DIR)

docker:
	@echo ">> building docker image"
	@docker build -t "$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)" .

promu:
	@GOOS=$(shell uname -s | tr A-Z a-z) \
		GOARCH=$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m))) \
		$(GO) get -u github.com/prometheus/promu
	
depend:
	#@$(GO) get -d github.com/ibmdb/go_ibm_db
	@rm -f $(GOPATH)/src/github.com/ibmdb/go_ibm_db/installer/clidriver
	@cd $(GOPATH)/src/github.com/ibmdb/go_ibm_db/installer/ && $(GO) run setup.go
	@echo "Dependencies Installed"	


.PHONY: all style format build test vet tarball docker promu depend
