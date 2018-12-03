# Package

import ospaths, strutils

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

requires "nim 0.19.0", "cligen 0.9.17", "uuids 0.1.10", "https://github.com/kdheepak/nimpy#head"

task librarywindows, "build library":
   exec("""nim c -d:crosswin -d:release --passc:"-flto" --app:lib --out:lib/_glm.pyd src/glm.nim""")
task libraryosx, "build library":
   exec("""nim c -d:release --passc:"-flto" --app:lib --out:lib/_glm.so src/glm.nim""")
task librarylinux, "build library":
   exec("""nim c -d:release --passc:"-flto" --app:lib --out:lib/_glm.so src/glm.nim""")
