docker build -t crits . && \

docker run --name crits -it \
  -p 27017:27017 -p 8443:8443 -ti crits /bin/bash
