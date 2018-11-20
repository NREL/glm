# Package

version       = "0.1.0"
author        = "Dheepak Krishnamurthy"
description   = "GLM package"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["glm2json", "json2glm"]

# Dependencies

requires "nim 0.19.0", "cligen 0.9.17", "https://github.com/kdheepak/nimpy#head"

task librarywindows, "build library":
   exec("""nim c -d:crosswin -d:release --passc:"-flto" --app:lib --out:lib/_glm.pyd src/glm.nim""")
task libraryosx, "build library":
   exec("""nim c -d:release --passc:"-flto" --app:lib --out:lib/_glm.so src/glm.nim""")
task librarylinux, "build library":
   exec("""nim c -d:release --passc:"-flto" --app:lib --out:lib/_glm.so src/glm.nim""")
