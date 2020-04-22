#!/bin/bash

mvn clean install
if docker build -t robinjohnhopkins/djshopfront . ; then
  docker push robinjohnhopkins/djshopfront
fi
