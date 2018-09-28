# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil

proc main*(): int =
    logger.info("Running main procedure")
    return 0


when isMainModule:
    import cligen
    cligen.dispatch(main)
