#!/bin/bash
make destroy-db
make stop-db
make clean-unnecessary-docker
make remove-docker-images
make refresh-docker-images