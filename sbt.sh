#!/bin/bash

if [ ! -z $JENKINS_URL ] ; then
  export SBT_OPTS="-Dsbt.log.noformat=true"
fi

sbt "$@"
