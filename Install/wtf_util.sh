#!/bin/bash

# Set the Go proxy variable to GoCenter
export GOPROXY="https://gocenter.io"

# Enable Go modules
export GO111MODULE=on

go get -u github.com/wtfutil/wtf
cd $GOPATH/src/github.com/wtfutil/wtf
make install
make run
