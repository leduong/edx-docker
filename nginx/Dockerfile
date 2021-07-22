ARG EDXAPP_STATIC_ROOT=/edx/app/edxapp/staticfiles
ARG NGINX_IMAGE_NAME=leduong/openedx-nginx
ARG NGINX_IMAGE_TAG=1.13
# === NGINX ===
FROM ${NGINX_IMAGE_NAME}:${NGINX_IMAGE_TAG} as nginx
ARG EDXAPP_STATIC_ROOT
RUN mkdir -p ${EDXAPP_STATIC_ROOT}
## Copy our default nginx config
#COPY ./docker/files/etc/nginx /etc/nginx
COPY ./etc/conf.d/lms.conf /etc/nginx/conf.d/lms.conf
COPY ./etc/conf.d/cms.conf /etc/nginx/conf.d/cms.conf
#COPY ./etc/conf.d/vlu.conf /etc/nginx/conf.d/vlu.conf

# COPY --from=files_collector ${EDXAPP_STATIC_ROOT} ${EDXAPP_STATIC_ROOT}
