# Package

import strutils
import os
import strformat

template thisModuleFile: string = instantiationInfo(fullPaths = true).filename

proc getGitVersion*(): string {.compileTime.} =
  return "0.4.2"

version       = getGitVersion()
author        = "Dheepak Krishnamurthy"
description   = "GLM package"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["glm2json", "json2glm"]

# Dependencies

requires "nim 1.2.6", "cligen 1.1.0", "uuids 0.1.10", "nimpy 0.1.0"

task release, "Clean and build release":
  when buildOS == "windows":
    exec("""nim c -d:release --opt:size --passc:"-flto" --app:lib --out:lib/_glm.pyd src/glm.nim""")
  else:
    exec("""nim c -d:release --opt:size  --passc:"-flto" --app:lib --out:lib/_glm.so src/glm.nim""")

task package, "Make Python Package":
  when buildOS == "windows":
    exec "python setup.py bdist_wheel --plat-name=win_amd64"
  elif buildOS == "macosx":
    exec "python setup.py bdist_wheel --plat-name=macosx_10_7_x86_64"
  else:
    exec "python setup.py bdist_wheel --plat-name=manylinux1_x86_64"
