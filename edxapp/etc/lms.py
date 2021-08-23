"""
Settings file for docker production
"""

# Silence noisy logs
import logging
import os

from corsheaders.defaults import default_headers as corsheaders_default_headers
# pylint: enable=unicode-format-string  # lint-amnesty, pylint: disable=bad-option-value
#####################################################################
from edx_django_utils.plugins import add_plugins
from openedx.core.djangoapps.plugins.constants import ProjectType, SettingsType

from .production import *  # pylint: disable=wildcard-import, unused-wildcard-import

WIKI_ENABLED = False
LMS_KEY = os.environ.get(
    'LMS_KEY', ENV_TOKENS.get('LMS_KEY', 'lms-key-openedx-vn'))
LMS_SECRET = os.environ.get(
    'LMS_SECRET', ENV_TOKENS.get('LMS_SECRET', 'lms-secret-openedx-vn'))
AWS_SES_REGION_NAME = os.environ.get(
    'AWS_SES_REGION_NAME', ENV_TOKENS.get('AWS_SES_REGION_NAME', ''))
AWS_ACCESS_KEY_ID = os.environ.get(
    'AWS_ACCESS_KEY_ID', ENV_TOKENS.get('AWS_ACCESS_KEY_ID', ''))
AWS_SECRET_ACCESS_KEY = os.environ.get(
    'AWS_SECRET_ACCESS_KEY', ENV_TOKENS.get('AWS_SECRET_ACCESS_KEY', ''))
AWS_QUERYSTRING_AUTH = bool(os.environ.get(
    'AWS_QUERYSTRING_AUTH', ENV_TOKENS.get('AWS_QUERYSTRING_AUTH', '')))
AWS_STORAGE_BUCKET_NAME = os.environ.get(
    'AWS_STORAGE_BUCKET_NAME', ENV_TOKENS.get('AWS_STORAGE_BUCKET_NAME', ''))
AWS_S3_CUSTOM_DOMAIN = os.environ.get(
    'AWS_S3_CUSTOM_DOMAIN', ENV_TOKENS.get('AWS_S3_CUSTOM_DOMAIN', ''))
COURSE_IMPORT_EXPORT_BUCKET = os.environ.get(
    'COURSE_IMPORT_EXPORT_BUCKET', ENV_TOKENS.get('COURSE_IMPORT_EXPORT_BUCKET', ''))
COURSE_METADATA_EXPORT_BUCKET = os.environ.get(
    'COURSE_METADATA_EXPORT_BUCKET', ENV_TOKENS.get('COURSE_METADATA_EXPORT_BUCKET', ''))

if AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY:
    AWS_DEFAULT_ACL = None
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto.S3BotoStorage'
else:
    # Don't use S3 in devstack, fall back to filesystem
    MEDIA_ROOT = "/edx/var/edxapp/uploads"
    ORA2_FILEUPLOAD_BACKEND = 'django'
    DEFAULT_FILE_STORAGE = 'django.core.files.storage.FileSystemStorage'

if COURSE_IMPORT_EXPORT_BUCKET:
    COURSE_IMPORT_EXPORT_STORAGE = 'cms.djangoapps.contentstore.storage.ImportExportS3Storage'
else:
    COURSE_IMPORT_EXPORT_STORAGE = DEFAULT_FILE_STORAGE

USER_TASKS_ARTIFACT_STORAGE = COURSE_IMPORT_EXPORT_STORAGE
if COURSE_METADATA_EXPORT_BUCKET:
    COURSE_METADATA_EXPORT_STORAGE = 'cms.djangoapps.export_course_metadata.storage.CourseMetadataExportS3Storage'
else:
    COURSE_METADATA_EXPORT_STORAGE = DEFAULT_FILE_STORAGE

USE_I18N = True

# By default don't use a worker, execute tasks as if they were local functions
CELERY_ALWAYS_EAGER = True
HTTPS = 'on'

LMS_ROOT_URL = f'http://{LMS_BASE}'
LMS_INTERNAL_ROOT_URL = LMS_ROOT_URL
ENTERPRISE_API_URL = f'{LMS_INTERNAL_ROOT_URL}/enterprise/api/v1/'
# IDA_LOGOUT_URI_LIST = [
#     'http://localhost:18130/logout/',  # ecommerce
#     'http://localhost:18150/logout/',  # credentials
#     'http://localhost:18381/logout/',  # discovery
# ]

################################ LOGGERS ######################################

LOG_OVERRIDES = [
    ('common.djangoapps.track.contexts', logging.CRITICAL),
    ('common.djangoapps.track.middleware', logging.CRITICAL),
    ('lms.djangoapps.discussion.django_comment_client.utils', logging.CRITICAL),
]
for log_name, log_level in LOG_OVERRIDES:
    logging.getLogger(log_name).setLevel(log_level)

# Docker does not support the syslog socket at /dev/log. Rely on the console.
LOGGING['handlers']['local'] = LOGGING['handlers']['tracking'] = {
    'class': 'logging.NullHandler',
}

LOGGING['loggers']['tracking']['handlers'] = ['console']


################################ OAUTH2 ######################################
JWT_AUTH.update({
    'JWT_AUDIENCE': 'lms-key',
    'JWT_ISSUER': f'{LMS_ROOT_URL}/oauth2',
    'JWT_ISSUERS': [{
        'AUDIENCE': 'lms-key',
        'ISSUER': f'{LMS_ROOT_URL}/oauth2',
        'SECRET_KEY': LMS_SECRET,
    }],
    'JWT_SECRET_KEY': LMS_SECRET,
    'JWT_SIGNING_ALGORITHM': 'RS512',
    'JWT_PRIVATE_SIGNING_JWK': (
        '{"e": "AQAB", "d": "RQ6k4NpRU3RB2lhwCbQ452W86bMMQiPsa7EJiFJUg-qBJthN0FMNQVbArtrCQ0xA1BdnQHThFiUnHcXfsTZUwmwvTu'
        'iqEGR_MI6aI7h5D8vRj_5x-pxOz-0MCB8TY8dcuK9FkljmgtYvV9flVzCk_uUb3ZJIBVyIW8En7n7nV7JXpS9zey1yVLld2AbRG6W5--Pgqr9J'
        'CI5-bLdc2otCLuen2sKyuUDHO5NIj30qGTaKUL-OW_PgVmxrwKwccF3w5uGNEvMQ-IcicosCOvzBwdIm1uhdm9rnHU1-fXz8VLRHNhGVv7z6mo'
        'ghjNI0_u4smhUkEsYeshPv7RQEWTdkOQ", "n": "smKFSYowG6nNUAdeqH1jQQnH1PmIHphzBmwJ5vRf1vu48BUI5VcVtUWIPqzRK_LDSlZYh'
        '9D0YFL0ZTxIrlb6Tn3Xz7pYvpIAeYuQv3_H5p8tbz7Fb8r63c1828wXPITVTv8f7oxx5W3lFFgpFAyYMmROC4Ee9qG5T38LFe8_oAuFCEntimW'
        'xN9F3P-FJQy43TL7wG54WodgiM0EgzkeLr5K6cDnyckWjTuZbWI-4ffcTgTZsL_Kq1owa_J2ngEfxMCObnzGy5ZLcTUomo4rZLjghVpq6KZxfS'
        '6I1Vz79ZsMVUWEdXOYePCKKsrQG20ogQEkmTf9FT_SouC6jPcHLXw", "q": "7KWj7l-ZkfCElyfvwsl7kiosvi-ppOO7Imsv90cribf88Dex'
        'cO67xdMPesjM9Nh5X209IT-TzbsOtVTXSQyEsy42NY72WETnd1_nAGLAmfxGdo8VV4ZDnRsA8N8POnWjRDwYlVBUEEeuT_MtMWzwIKU94bzkWV'
        'nHCY5vbhBYLeM", "p": "wPkfnjavNV1Hqb5Qqj2crBS9HQS6GDQIZ7WF9hlBb2ofDNe2K2dunddFqCOdvLXr7ydRcK51ZwSeHjcjgD1aJkHA'
        '9i1zqyboxgd0uAbxVDo6ohnlVqYLtap2tXXcavKm4C9MTpob_rk6FBfEuq4uSsuxFvCER4yG3CYBBa4gZVU", "kid": "devstack_key", "'
        'kty": "RSA"}'
    ),
    'JWT_PUBLIC_SIGNING_JWK_SET': (
        '{"keys": [{"kid": "devstack_key", "e": "AQAB", "kty": "RSA", "n": "smKFSYowG6nNUAdeqH1jQQnH1PmIHphzBmwJ5vRf1vu'
        '48BUI5VcVtUWIPqzRK_LDSlZYh9D0YFL0ZTxIrlb6Tn3Xz7pYvpIAeYuQv3_H5p8tbz7Fb8r63c1828wXPITVTv8f7oxx5W3lFFgpFAyYMmROC'
        '4Ee9qG5T38LFe8_oAuFCEntimWxN9F3P-FJQy43TL7wG54WodgiM0EgzkeLr5K6cDnyckWjTuZbWI-4ffcTgTZsL_Kq1owa_J2ngEfxMCObnzG'
        'y5ZLcTUomo4rZLjghVpq6KZxfS6I1Vz79ZsMVUWEdXOYePCKKsrQG20ogQEkmTf9FT_SouC6jPcHLXw"}]}'
    ),
})
add_plugins(__name__, ProjectType.LMS, SettingsType.PRODUCTION)