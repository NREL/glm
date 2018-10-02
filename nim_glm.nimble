# Package

version       = "0.1.0"
author        = "Dheepak Krishnamurthy"
description   = "GLM package"
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["glm"]

# Dependencies

requires "nim >= 0.19.0", "cligen#head", "nimpy"

task library, "build library":
    when defined(crosswin):
        exec("nim c --app:lib --out:lib/glm.pyd src/glm.nim")
    else:
        exec("nim c --app:lib --out:lib/glm.so src/glm.nim")
