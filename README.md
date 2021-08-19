# Open edX Docker [Join Slack channels](https://join.slack.com/share/zt-ul2o0flf-XRl1J7HYuvnP7FohdGnI4Q) 
<a href="https://www.buymeacoffee.com/leduong" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="32" /></a> 

The Open edX software, inclusive of all system software and third party libraries, is free to download and free to use. edX releases a major update to the software around once per year. The software is controlled by edX but maintained by a consortium of community users consting mostly the engineering team at edX itself along with contributions from member universities around the world. This group does not charge fees for access to their regular software updates. Your only costs will be external consulting costs, if any, for the installation and configuration, and recurring cloud computing costs. My blog article, "How Much Does Open edX Cost?" includes summaries of itemized projects costs that have been voluntarily submitted by user in the Open edX community over the last few years.

## Demo Site [edxdemo.site](https://edxdemo.site)

## Getting Started


### Prerequisites

You will need to have the following installed:

- make
- Python 3.8
- Docker

This project requires **Docker 17.06+ CE**.  We recommend Docker Stable, but
Docker Edge should work as well.

**NOTE:** Switching between Docker Stable and Docker Edge will remove all images and
settings.  Don't forget to restore your memory setting and be prepared to
provision.

For macOS users, please use `Docker for Mac`_. Previous Mac-based tools (e.g.
boot2docker) are *not* supported.

Since a Docker-based devstack runs many containers,
you should configure Docker with a sufficient
amount of resources. We find that `configuring Docker for Mac`_
with a minimum of **2 CPUs, 8GB of memory, and a disk image size of 96GB**
does work.

`Docker for Windows`_ may work but has not been tested and is *not* supported.

If you are using Linux, use the ``overlay2`` storage driver, kernel version
4.0+ and *not* ``overlay``. To check which storage driver your
``docker-daemon`` uses, run the following command.

.. code:: sh

   docker info | grep -i 'storage driver'


Make sure you have a recent version of [Docker](https://docs.docker.com/install)
and [Docker Compose](https://docs.docker.com/compose/install) installed on your
laptop:

```bash
$ docker -v
  Docker version 17.12.0-ce, build c97c6d6

$ docker-compose --version
  docker-compose version 1.17.1, build 6d101fb
```

⚠️ `Docker Compose` version 1.19 is not supported because of a bug (see
https://github.com/docker/compose/issues/5686). Please downgrade to 1.18 or
upgrade to a higher version.

## Getting started

First, you need to set ENV for  a release/flavor of OpenEdx versions we support.

### Copy/paste lilac/1 environment:

```
export EDX_RELEASE="lilac.1"
export EDX_RELEASE_REF="open-release/lilac.master"
export EDX_DEMO_RELEASE_REF="open-release/lilac.1"

# Check your environment with:
make info
```

Once your environment is set, start the full project by running:

```bash
$ make bootstrap
```

You should now be able to view the web applications:

- LMS served by `nginx` at: [http://localhost:18000](http://localhost:18000)
- CMS served by `nginx` at: [http://localhost:18010](http://localhost:18010)

See other available commands by running:

```bash
$ make --help
```

### Start Production

```
make run
```

## Developer guide

If you intend to work on edx-platform or its configuration, you'll need to
compile static files in local directories that are mounted as docker volumes in
the target container:

```bash
$ export DOCKER_GID=$(id -g) && DOCKER_UID=$(id -u) && make permission
$ make dev-assets
```

Now you can start services development server _via_:

```bash
$ make dev
```

You should be able to view the web applications:

- LMS served by Django's development server at:
  [http://localhost:18000](http://localhost:18000)
- CMS served by Django's development server at:
  [http://localhost:18010](http://localhost:18010)

### Hacking with themes

To work on a particular theme, we invite you to use the `paver watch_assets`
command; _e.g._:

```bash
$ make dev-watch
```

**Troubleshooting**: if the command above raises the following error:

```
OSError: inotify watch limit reached
```

Then you will need to increase the **host**'s `fs.inotify.max_user_watches`
kernel setting (for reference, see https://unix.stackexchange.com/a/13757):

```ini
# /etc/sysctl.conf (debian based)
fs.inotify.max_user_watches=524288
```
## Reference

- Reference from [FUN](https://github.com/openfun/openedx-docker). Thanks

## License

The code in this repository is licensed under the GNU AGPL-3.0 terms unless
otherwise noted.

Please see [`LICENSE`](./LICENSE) for details.
