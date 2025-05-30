//#region Imports
const {PreProcessor} = require("./functions/preprocessResource")
const {isLeapDependency, hasAnyFileBeenModified, relativeToAbs} = require("./functions/utils")
const {rmSync} = require("fs")
//#endregion

//#region Build Task
let leapBuildTask = {
    shouldBuild(res) {
        return isLeapDependency(res) && hasAnyFileBeenModified(res)
    },
    build(res, cb) {
        // We need to use this trick as the build function cant be directly async
        let buildleap = async () => {
            try {
                const preprocessor = new PreProcessor(res)
                try {
                    await preprocessor.run()
                    await preprocessor.setPathsAsBuildRelative()
                    await preprocessor.writeCache()
                } catch (e) {
                    cb(false, e.message)
                    return
                }

                cb(true)
            } catch (e) {
                cb(false, e.message)
            }
        }

        buildleap().then()
    }
}

// Register the build task after the server loaded (setImmediate runs immediately after the first tick in the main thread, that's started after the server loaded)
setImmediate(() => {
    RegisterResourceBuildTaskFactory("leap", () => leapBuildTask)
})
//#endregion

//#region Command
RegisterCommand("leap", async (source, args) => {
    if (source != 0) return // only server side can use the command

    let [type, resourceName] = args

    // No type or resource provided, display help
    if (!type || !resourceName) {
        console.log(`leap restart <resource>`)
        console.log(`leap build <resource>`)
        return
    }

    let preprocessor = new PreProcessor(resourceName)

    switch(type) {
        case "build": {
            const _path = relativeToAbs("build/", resourceName)
            rmSync(_path, {recursive: true, force: true})

            await preprocessor.run(true)
            await preprocessor.setPathsAsBuildRelative()
            console.log(`^2Builded ${resourceName} successfully^0`)

            break;
        }
        case "restart": {
            StopResource(resourceName)

            await preprocessor.run()
            await preprocessor.setPathsAsBuildRelative()
            await preprocessor.writeCache()

            StartResource(resourceName)
            break;
        }
    }

}, true)
//#endregion