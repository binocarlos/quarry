#!/bin/bash
imagename=${1:-quarry/base}
imagefolder=${2:-dockerfiles/base}
silent=${3:-}
docker build -t ${imagename} $silent ${imagefolder}