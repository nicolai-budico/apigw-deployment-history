#!/bin/sh

aws lambda remove-permission \
  --statement-id "${STATEMENT_ID}" \
  --function-name "${FUNCTION_NAME}" \
  --qualifier "${QUALIFIER}" \
  1>&2
