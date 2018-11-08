# crossbuild-icinga2-debian
Cross-compile icinga2 packages for ARM architectures (you can build for every achitecture).

# Requirements

- You will need at least 3GB space for your docker containers
- Minimally 2GBs of RAM are necessary to compile icinga2
- Host, which compiles icinga2 obviously has to be `x86_64`

# Usage

```
git clone https://github.com/bebehei/crossbuild-icinga2-debian
docker build -t icinga2-crossbuild crossbuild-icinga2-debian
```

An image `icinga2-crossbuild` will be the product, which contains only the deb packages for icinga2, nothing more. You can use this to build your own image with a Dockerfile.

You can either use this now to build a container:

Example:

```
FROM debian:stretch as production

COPY --from=icinga2-crossbuild /pkgs/*.deb /pkgs
RUN dpkg -i /pkgs/* \
 && apt-get install -f
```

If you need the packages somewhere else, copy the image to you host machine via SSH: `docker image save debiancrossbuild | ssh <host> docker image load`

Or, if you need the packages locally without docker, run this command:

```
docker run --rm -v "$PWD/pkgs:/gimmepkgs" icinga2-crossbuild 
```

And the packages are located in your `./pkgs`.
