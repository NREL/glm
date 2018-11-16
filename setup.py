# -*- coding: utf-8 -*-
from setuptools import setup, Distribution
import subprocess
import shlex


class BinaryDistribution(Distribution):

    def has_ext_modules(self):
        return True


version = (
    subprocess.check_output(shlex.split("git describe --tags HEAD"))
    .decode()
    .strip()
    .split("-")[0]
    .strip("v")
)

setup(
    name="glm",
    version=version,
    description="glm Python library",
    distclass=BinaryDistribution,
)
