#!/bin/bash
timeout 300 bash -c 'while [[ "$(curl -k -s -o /dev/null -w ''%{http_code}'' https://'$1')" != "200" ]]; do sleep 5; done' || false
timeout 300 bash -c 'while [[ "$(curl -k -s -o /dev/null -w ''%{http_code}'' https://'$1'/api/v0/ui/)" != "200" ]]; do sleep 5; done' || false