#!/bin/bash

# Deploys Maverick runtime assets next to the compiled game.
# GAGS reads its json configs and icons from disk at runtime, and iconforge
# reads icons from disk for spritesheets. Without these copies, CI and live
# deploys fail to load any Maverick GAGS config.
# $1 is the deploy target, same as tools/deploy.sh.

if [ -d modular_~maverick/icons ]; then
	mkdir -p $1/modular_~maverick/icons
	cp -r modular_~maverick/icons/* $1/modular_~maverick/icons/
fi

for configdir in $(find modular_~maverick -type d -name "json_configs" 2>/dev/null)
do
	mkdir -p $1/$configdir
	cp -r $configdir/* $1/$configdir/
done
