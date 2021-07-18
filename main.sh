#!/bin/bash

# jekyll serve --watch --force_polling

CON="inesyra-blog-500_0.0.1"
IMA="inesyra/blog-500:0.0.1"


if [ $1 = "up" ]; then
    docker start $CON 2>/dev/null || \
    docker run -d -p 4000:4000 -v $(pwd):"/app" -v $(pwd):"/home/docker" --name $CON $IMA
    echo "Done"
fi


if [ $1 = "build" ]; then
    docker container rm -f $CON >/dev/null 2>&1 || cat /dev/null
    docker rmi $(docker images --format="{{.ID}}" --filter="reference=$IMA") >/dev/null 2>&1 || cat /dev/null
    docker build -t $IMA .
fi


if [ $1 = "down" ]; then
    docker stop $CON
fi


if [ $1 = "ssh" ]; then
    docker exec -it --privileged $CON /bin/bash
fi
