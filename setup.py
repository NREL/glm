# -*- coding: utf-8 -*-
from setuptools import setup, Distribution
import subprocess
import shlex
import os
import shutil

from sys import platform


# Tested with wheel v0.29.0
class BinaryDistribution(Distribution):
    """Distribution which always forces a binary package with platform name"""

    def has_ext_modules(self):
        return True


version = (
    subprocess.check_output(shlex.split("git describe --tags HEAD"))
    .decode()
    .strip()
    .split("-")[0]
    .strip("v")
)

if os.getenv("BUILD") == "windows" or platform == "win32":
    ext = "pyd"
elif platform == "darwin":
    ext = "so"
elif platform == "linux" or platform == "linux2":
    ext = "so"


def setup_package():
    if not os.path.exists("./glm"):
        os.makedirs("./glm")
    shutil.copy("./lib/glm.{}".format(ext), "./glm/")
    with open("./glm/__init__.py", "w") as f:
        f.write("""from .glm import *""".strip())
    with open("./MANIFEST.in", "w") as f:
        f.write("recursive-include ./glm/ glm.*")


setup_package()

setup(
    name="glm",
    version=version,
    description="glm Python library",
    packages=["glm"],
    scripts=["bin/glm2json", "bin/json2glm"],
    author="Dheepak Krishnamurthy",
    author_email="me@kdheepak.com",
    url="https://github.com/NREL/glm",
    distclass=BinaryDistribution,
)
