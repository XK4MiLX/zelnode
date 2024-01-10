#!/bin/bash
if [[ -f /usr/local/bin/flux-cli ]]; then
   bash -c "flux-cli stop"
else
   bash -c "zelcash-cli stop"
fi
exit
