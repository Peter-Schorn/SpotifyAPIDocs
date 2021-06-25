import Vapor
import VaporDocC
import Foundation

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
app.http.server.configuration.hostname = "0.0.0.0"


guard let docCArchiveURL = docCArchiveURL else {
    fatalError("could not find SpotifyWebAPI.doccarchive in bundle")
}

let redirectRoot = "documentation/SpotifyWebAPI"
let redirectMissingTrailingSlash = ProcessInfo.processInfo.environment["REDIRECT_MISSING_TRAILING_SLASH"] == "TRUE"

let middleware = VaporDocCMiddleware(
    archivePath: docCArchiveURL,
    redirectRoot: redirectRoot,
    redirectMissingTrailingSlash: true
)
app.middleware.use(middleware)
try app.run()
