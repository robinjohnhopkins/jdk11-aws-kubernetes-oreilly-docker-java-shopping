#!/bin/bash

mvn clean install
if docker build -t robinjohnhopkins/djstockmanager . ; then
  docker push robinjohnhopkins/djstockmanager
fi
