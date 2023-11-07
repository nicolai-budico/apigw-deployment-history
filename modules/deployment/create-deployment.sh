#!/bin/bash

set -e

aws apigateway create-deployment --rest-api-id  "${REST_API_ID}" --description "${DESCRIPTION}"
