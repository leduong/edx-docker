#!/usr/bin/env python

from student.models import UserProfile
from django.contrib.auth.models import User

import django

django.setup()


# Create a normal user
try:
    edx = User.objects.get(username="edx")
except User.DoesNotExist:
    edx = User.objects.create(
        username="edx", email="edx@example.com", is_active=True)
    edx.set_password("edx")
    edx.save()
    UserProfile.objects.create(user=edx)

# Create a superuser
try:
    admin = User.objects.get(username="admin")
except User.DoesNotExist:
    admin = User.objects.create(
        username="admin",
        email="admin@example.com",
        is_active=True,
        is_superuser=True,
        is_staff=True,
    )
    admin.set_password("admin")
    admin.save()
    UserProfile.objects.create(user=admin)

