import Vapor
import VaporDocC
import Foundation

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }
app.http.server.configuration.hostname = "0.0.0.0"


#if DEBUG

guard let docCArchiveURL = docCArchiveURL else {
    fatalError("could not find SpotifyWebAPI.doccarchive in bundle")
}

#else  // RELEASE configuration on heroku

let path = "/app/.swift-bin/SpotifyAPIDocs_VaporDocC.resources"

let contents = try FileManager.default.contentsOfDirectory(
    atPath: path
)
print("found \(contents.count) items in folder \(path)")
for file in contents {
    print(file)
}
print("---")

guard let bundle = Bundle(path: path) else {
    fatalError("could not create bundle from path \(path)")
}
guard let docCArchiveURL = bundle.url(
    forResource: "SpotifyWebAPI", withExtension: "doccarchive"
) else {
    fatalError("could not find SpotifyWebAPI.doccarchive in bundle")
}

#endif

print("docCArchiveURL: \(docCArchiveURL)")

let redirectRoot = ProcessInfo.processInfo.environment["REDIRECT_ROOT"]!
print("redirectRoot: \(redirectRoot)")

let middleware = VaporDocCMiddleware(
    archivePath: docCArchiveURL,
    redirectRoot: redirectRoot,
    redirectMissingTrailingSlash: true
)
app.middleware.use(middleware)
try app.run()
