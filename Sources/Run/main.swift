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
if let resourceURL = bundle.resourceURL {
    let contents = try FileManager.default.contentsOfDirectory(
        atPath: resourceURL.path
    )
    print("found \(contents.count) items in resourceURL \(path)")
    for file in contents {
        print(file)
    }
    print("---")
}
else {
    print("bundle.resourceURL was nil")
}
guard let docCArchiveURL = bundle.url(
    forResource: "SpotifyWebAPI", withExtension: "doccarchive"
) else {
    fatalError("could not find SpotifyWebAPI.doccarchive in bundle")
}

#endif

print("docCArchiveURL: \(docCArchiveURL)")

let redirectRoot = "documentation/SpotifyWebAPI"
let redirectMissingTrailingSlash = ProcessInfo.processInfo.environment[
    "REDIRECT_MISSING_TRAILING_SLASH"
] == "TRUE"

let middleware = VaporDocCMiddleware(
    archivePath: docCArchiveURL,
    redirectRoot: redirectRoot,
    redirectMissingTrailingSlash: true
)
app.middleware.use(middleware)
try app.run()
