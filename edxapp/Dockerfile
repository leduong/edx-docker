ARG EDXAPP_STATIC_ROOT=/edx/var/edxapp/staticfiles
ARG NGINX_IMAGE_NAME=leduong/openedx-nginx
ARG NGINX_IMAGE_TAG=1.13
ARG OPENEDX_IMAGE=leduong/openedx-lilac
ARG OPENEDX_VERSION=1

# === BASE ===
FROM ${OPENEDX_IMAGE}:${OPENEDX_VERSION} as base
COPY ./edx-platform .
ENV DJANGO_SETTINGS_MODULE ""
RUN mkdir -p test_root/log

# === DEVELOPMENT ===
FROM base as development
ENV DJANGO_SETTINGS_MODULE ""

ARG DOCKER_UID
ARG DOCKER_GID

RUN groupadd --gid ${DOCKER_GID} edx || echo "Group with ID ${DOCKER_GID} already exists."
RUN useradd --uid ${DOCKER_UID} --gid ${DOCKER_GID} edx || echo "Skip user creation (user with ID ${DOCKER_UID} already exists?)"

RUN chown -R ${DOCKER_UID}:${DOCKER_GID} /edx
USER ${DOCKER_UID}:${DOCKER_GID}

# Copy the entrypoint that will activate the virtualenv
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

ENV SERVICE_VARIANT lms
ENV DJANGO_SETTINGS_MODULE lms.envs.devstack_decentralized
CMD python /edx/app/edxapp/edx-platform/manage.py ${SERVICE_VARIANT} runserver 0.0.0.0:8000
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]

# === BUILDER ===
FROM base as builder
# Update assets skipping collectstatic (it should be done during deployment)
RUN NO_PREREQ_INSTALL=1 paver update_assets --settings=production --skip-collect

# === STATIC LINKS COLLECTOR ===
FROM builder as collectstatic
RUN python manage.py lms collectstatic --link --noinput --settings production && \
    python manage.py cms collectstatic --link --noinput --settings production

FROM builder as links_collector
ARG EDXAPP_STATIC_ROOT
# Replace duplicated file by a symlink to decrease the overall size of the
# final image
RUN rdfind -makesymlinks true -followsymlinks true ${EDXAPP_STATIC_ROOT}

# === STATIC FILES COLLECTOR ===
FROM collectstatic as files_collector
ARG EDXAPP_STATIC_ROOT
# Replace duplicated file by a symlink to decrease the overall size of the
# final image
RUN rdfind -makesymlinks true ${EDXAPP_STATIC_ROOT}
RUN find ${EDXAPP_STATIC_ROOT} -type l -exec sed -i '' {} \;

# === EXDAPP BUILDER ===
FROM base as exdapp
ARG EDXAPP_STATIC_ROOT
ENV SERVICE_VARIANT lms
ENV DJANGO_SETTINGS_MODULE lms.envs.production
EXPOSE 8000
COPY --from=links_collector ${EDXAPP_STATIC_ROOT} ${EDXAPP_STATIC_ROOT}
CMD gunicorn -c /edx/app/edxapp/edx-platform/${SERVICE_VARIANT}/docker_${SERVICE_VARIANT}_gunicorn.py \
    --name ${SERVICE_VARIANT} \
    --bind=0.0.0.0:8000 \
    --max-requests=1000 \
    --access-logfile - ${SERVICE_VARIANT}.wsgi:application

# === PRODUCTION ===
FROM exdapp as production
# Copy over remaining code.
# We do this as late as possible so that small changes to the repo don't bust
# the requirements cache.
COPY ./etc/lms.yml /edx/etc/lms.yml
COPY ./etc/studio.yml /edx/etc/studio.yml
COPY ./etc/lms.py ./lms/envs
COPY ./etc/cms.py ./cms/envs

# === NGINX ===
FROM ${NGINX_IMAGE_NAME}:${NGINX_IMAGE_TAG} as nginx
ARG EDXAPP_STATIC_ROOT
RUN mkdir -p ${EDXAPP_STATIC_ROOT}

COPY ./nginx/conf.d/lms.conf /etc/nginx/conf.d/lms.conf
COPY ./nginx/conf.d/cms.conf /etc/nginx/conf.d/cms.conf

COPY --from=files_collector ${EDXAPP_STATIC_ROOT} ${EDXAPP_STATIC_ROOT}