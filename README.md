
# CRITs Docker Image

This is a docker image for [CRITs](https://github.com/crits/crits),
based on the REMnux image, with the following changes:

- Uses `phusion-baseimage-latest` as a base image.
- Uses TokuMX instead of vanilla MongoDB.
- Uses a dedicated `/data` volume for the database and the certificates.
- Certificates are created at container creation.
- Services are installed in `/opt/crits_services`.
- Works with the latest CRITs code.

# Instructions

```bash
$ docker build -t crits .

$ docker run --name crits -it \
  -v ~/crits-data/db:/data/db \
  -v ~/crits-data/ssl:/data/ssl \
  -p 8443:8443 -p 27017:27017 crits
```

Connect to `https://<external IP>:8443`, create sources, add users,
enable services, turn off the debug mode.

In order to start the container later:

```bash
$ docker start crits
```

In order to restart the service, kill the `manage.py runserver` process.
