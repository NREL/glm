# Package

import strutils
import os
import strformat

template thisModuleFile: string = instantiationInfo(fullPaths = true).filename

proc getGitVersion*(): string {.compileTime.} =
  return "0.4.4"

version       = getGitVersion()
author        = "Dheepak Krishnamurthy"
description   = "GLM package"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["glm2json", "json2glm"]

# Dependencies

requires "nim 1.6.12", "cligen 1.6.0", "uuids 0.1.11", "nimpy 0.2.0"

task release, "Clean and build release":
  when buildOS == "windows":
    exec("""nim c -d:release --opt:size --passC:"-flto" --app:lib --out:lib/_glm.pyd src/glm.nim""")
  elif buildOS == "macosx" and buildCPU == "x86_64":
    exec("""nim c -d:release --opt:size --cpu:x86_64  --passC:"-flto" --passL:"-flto" --app:lib --out:lib/_glm.so src/glm.nim""")
  elif buildOS == "macosx" and buildCPU == "amd64":
    exec("""nim c -d:release --opt:size --cpu:arm64 --passC:"-flto -target arm64-apple-macos11" --passL:"-flto -target arm64-apple-macos11" --app:lib --out:lib/_glm.so src/glm.nim""")
  else:
    exec("""nim c -d:release --opt:size  --passC:"-flto" --app:lib --out:lib/_glm.so src/glm.nim""")

task package, "Make Python Package":
  when buildOS == "windows":
    exec "python setup.py bdist_wheel --plat-name=win_amd64"
  elif buildOS == "macosx" and buildCPU == "x86_64":
    exec "python setup.py bdist_wheel --plat-name=macosx_10_7_x86_64"
  elif buildOS == "macosx" and buildCPU == "amd64":
    exec "python setup.py bdist_wheel --plat-name=macosx_11_0_arm64"
  else:
    exec "python setup.py bdist_wheel --plat-name=manylinux1_x86_64"
