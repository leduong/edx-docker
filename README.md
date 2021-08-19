# Open edX Docker

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

### Set Environment and Build

```
$ export EDX_RELEASE="lilac.1"
$ export EDX_RELEASE_REF="open-release/lilac.master"
$ export EDX_DEMO_RELEASE_REF="open-release/lilac.1"
$ make bootstrap
```

### Start Production

```
make run
```

### Start Development

```
make dev
```

## License

The code in this repository is licensed under the GNU AGPL-3.0 terms unless
otherwise noted.

Please see [`LICENSE`](./LICENSE) for details.
