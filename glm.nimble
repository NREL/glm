# Package

import strutils
import os
import strformat

template thisModuleFile: string = instantiationInfo(fullPaths = true).filename

proc getGitVersion*(): string {.compileTime.} =
    const v = staticExec("git describe --tags HEAD")[1..5]
    if v == "atal:":
        const version = thisModuleFile.split(DirSep)[^2].split("-")[^1]
        if version.split(".").len != 3:
            return "0.1.0"
        else:
            return version
    else:
        return v

version       = getGitVersion()
author        = "Dheepak Krishnamurthy"
description   = "GLM package"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["glm2json", "json2glm"]

# Dependencies

requires "nim 1.2.0", "cligen 1.1.0", "uuids 0.1.10", "nimpy 0.1.0"

before build:
  rmDir(binDir)

after build:
  when buildOS == "windows":
    let cli = packageName & ".exe"
  else:
    let cli = packageName
  mvFile binDir / cli, binDir / cli.replace("_cli", "")

proc package(packageOs: string, packageCpu: string) =
  let cli = packageName.replace("_cli", "")
  let assets = &"{cli}-v{version}-{packageOs}-{packageCpu}"
  let dist = "dist"
  let distDir = dist / assets
  rmDir distDir
  mkDir distDir
  cpDir binDir, distDir / binDir
  cpFile "LICENSE", distDir / "LICENSE"
  cpFile "README.md", distDir / "README.md"
  when buildOS == "windows":
    exec "python3 setup.py bdist_wheel --plat-name=win_amd64"
  elif buildOS == "macos":
    exec "python3 setup.py bdist_wheel --plat-name=macosx_10_7_x86_64"
  else:
    exec "python3 setup.py bdist_wheel --plat-name=manylinux1_x86_64"

task clean, "Clean project":
  rmDir(nimcacheDir())

task changelog, "Create a changelog":
  exec("./scripts/changelog.nim")

task debug, "Clean and build debug":
  exec "nimble clean"
  exec "nimble build"

task release, "Clean and build release":
  exec "nimble clean"
  when buildOS == "windows":
    exec("""nim c -d:release --opt:size --passc:"-flto" --app:lib --out:lib/_glm.pyd src/glm.nim""")
  else:
    exec("""nim c -d:release --opt:size  --passc:"-flto" --app:lib --out:lib/_glm.so src/glm.nim""")
  package(buildOS, buildCPU)
