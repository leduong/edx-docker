ARG EDXAPP_STATIC_ROOT=/edx/app/edxapp/staticfiles
ARG NGINX_IMAGE_NAME=leduong/openedx-nginx
ARG NGINX_IMAGE_TAG=1.13

# === BASE ===
FROM ubuntu:focal as base

# Warning: This file is experimental.

# Install system requirements
RUN apt-get update && \
    # Global requirements
    DEBIAN_FRONTEND=noninteractive apt-get install --yes \
    build-essential \
    curl \
    # If we don't need gcc, we should remove it.
    g++ \
    gcc \
    git \
    git-core \
    language-pack-en \
    libfreetype6-dev \
    libmysqlclient-dev \
    libssl-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libxslt1-dev \
    swig \
    # openedx requirements
    gettext \
    gfortran \
    graphviz \
    libffi-dev \
    libfreetype6-dev \
    libgeos-dev \
    libgraphviz-dev \
    libjpeg8-dev \
    liblapack-dev \
    libpng-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libxslt1-dev \
    # lynx: Required by https://github.com/edx/edx-platform/blob/b489a4ecb122/openedx/core/lib/html_to_text.py#L16
    lynx \
    ntp \
    rdfind \
    pkg-config \
    python3-dev \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /edx/app/edxapp/edx-platform

ENV PATH /edx/app/edxapp/nodeenv/bin:${PATH}
ENV PATH ./node_modules/.bin:${PATH}
ENV CONFIG_ROOT /edx/etc/
ENV PATH /edx/app/edxapp/edx-platform/bin:${PATH}
ENV SETTINGS production
ENV LMS_CFG /edx/etc/lms.yml
ENV STUDIO_CFG /edx/etc/studio.yml
ENV VIRTUAL_ENV=/edx/app/edxapp/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN python3.8 -m venv $VIRTUAL_ENV
RUN mkdir -p /edx/etc/
COPY ./etc/lms.yml /edx/etc/lms.yml
COPY ./etc/studio.yml /edx/etc/studio.yml

# Copy over remaining code.
# We do this as late as possible so that small changes to the repo don't bust
# the requirements cache.
COPY ./edx-platform .

# Install Python requirements
RUN pip install -r requirements/pip.txt
RUN pip install -r requirements/edx/base.txt
RUN pip install .
RUN nodeenv /edx/app/edxapp/nodeenv --node=12.11.1 --prebuilt
RUN npm set progress=false && npm install

# === DEVELOPMENT ===
FROM base as development

ARG DOCKER_UID
ARG DOCKER_GID

RUN groupadd --gid ${DOCKER_GID} edx || echo "Group with ID ${DOCKER_GID} already exists."
RUN useradd --uid ${DOCKER_UID} --gid ${DOCKER_GID} edx || echo "Skip user creation (user with ID ${DOCKER_UID} already exists?)"

RUN chown -R ${DOCKER_UID}:${DOCKER_GID} /edx/app/edxapp

# Copy the entrypoint that will activate the virtualenv
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

# Switch to an un-privileged user matching the host user to prevent permission
# issues with volumes (host folders)
USER ${DOCKER_UID}:${DOCKER_GID}

# Install development dependencies in a virtualenv
RUN bash -c "source /edx/app/edxapp/.venv/bin/activate && \
    pip install --no-cache-dir -r requirements/edx/testing.txt && \
    pip install --no-cache-dir -r requirements/edx/development.txt"

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]


FROM development as lms-dev
# TODO: This compiles static assets.
# However, it's a bit of a hack, it's slow, and it's inefficient because makes the final Docker cache layer very large.
# We ought to be able to this higher up in the Dockerfile, and do it the same for Prod and Devstack.
RUN mkdir -p test_root/log
ENV DJANGO_SETTINGS_MODULE ""
RUN NO_PREREQ_INSTALL=1 paver update_assets lms --settings devstack_decentralized
ENV DJANGO_SETTINGS_MODULE lms.envs.devstack_decentralized

FROM development as studio-dev
# TODO: This compiles static assets.
# However, it's a bit of a hack, it's slow, and it's inefficient because makes the final Docker cache layer very large.
# We ought to be able to this higher up in the Dockerfile, and do it the same for Prod and Devstack.
RUN mkdir -p test_root/log
ENV DJANGO_SETTINGS_MODULE ""
RUN NO_PREREQ_INSTALL=1 paver update_assets cms --settings devstack_decentralized
ENV DJANGO_SETTINGS_MODULE cms.envs.devstack_decentralized

# === PRODUCTION ===
FROM base as lms
ARG EDXAPP_STATIC_ROOT
ENV SERVICE_VARIANT lms
ENV DJANGO_SETTINGS_MODULE lms.envs.production
EXPOSE 8000
CMD gunicorn -c /edx/app/edxapp/edx-platform/lms/docker_lms_gunicorn.py --name lms --bind=0.0.0.0:8000 --max-requests=1000 --access-logfile - lms.wsgi:application

FROM base as studio
ARG EDXAPP_STATIC_ROOT
ENV SERVICE_VARIANT cms
ENV DJANGO_SETTINGS_MODULE cms.envs.production
EXPOSE 8000
CMD gunicorn -c /edx/app/edxapp/edx-platform/cms/docker_cms_gunicorn.py --name cms --bind=0.0.0.0:8000 --max-requests=1000 --access-logfile - cms.wsgi:application


# === NGINX ===
FROM ${NGINX_IMAGE_NAME}:${NGINX_IMAGE_TAG} as nginx
ARG EDXAPP_STATIC_ROOT
RUN mkdir -p ${EDXAPP_STATIC_ROOT}

COPY ./nginx/etc/conf.d/lms.conf /etc/nginx/conf.d/lms.conf
COPY ./nginx/etc/conf.d/cms.conf /etc/nginx/conf.d/cms.conf

# COPY --from=files_collector ${EDXAPP_STATIC_ROOT} ${EDXAPP_STATIC_ROOT}