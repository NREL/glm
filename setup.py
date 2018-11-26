# -*- coding: utf-8 -*-
from setuptools import setup
import subprocess
import shlex
import os
import shutil

from sys import platform

from wheel.bdist_wheel import bdist_wheel as _bdist_wheel

from setuptools.dist import Distribution


class BinaryDistribution(Distribution):

    def is_pure(self):
        return False


class bdist_wheel(_bdist_wheel):

    def finalize_options(self):
        _bdist_wheel.finalize_options(self)
        # Mark us as not a pure python package
        self.root_is_pure = False

    def get_tag(self):
        python, abi, plat = _bdist_wheel.get_tag(self)
        # We don't contain any python source
        python, abi = "py2.py3", "none"
        return python, abi, plat


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
    shutil.copy("./lib/_glm.{}".format(ext), "./glm/")
    with open("./glm/__init__.py", "w") as f:
        f.write(
            """from ._glm import *
__version__ = version()
""".strip()
        )
    with open("./MANIFEST.in", "w") as f:
        f.write("recursive-include ./glm/ _glm.*")


setup_package()

setup(
    name="glm",
    version=version,
    description="glm Python library",
    packages=["glm"],
    author="Dheepak Krishnamurthy",
    author_email="me@kdheepak.com",
    url="https://github.com/NREL/glm",
    zip_safe=False,
    cmdclass={"bdist_wheel": bdist_wheel},
    include_package_data=True,
    distclass=BinaryDistribution,
    package_data={"glm": ["*{}".format(ext)]},
)
