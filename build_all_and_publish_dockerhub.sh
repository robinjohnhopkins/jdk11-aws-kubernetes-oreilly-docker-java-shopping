#!/bin/bash

cd shopfront
mvn clean install
if docker build -t robinjohnhopkins/djshopfront . ; then
  docker push robinjohnhopkins/djshopfront
fi
cd ..

cd productcatalogue
mvn clean install
if docker build -t robinjohnhopkins/djproductcatalogue . ; then
  docker push robinjohnhopkins/djproductcatalogue
fi
cd ..

cd stockmanager
mvn clean install
if docker build -t robinjohnhopkins/djstockmanager . ; then
  docker push robinjohnhopkins/djstockmanager
fi
cd ..
