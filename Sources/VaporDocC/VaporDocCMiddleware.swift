import Vapor

/// Vapor middleware that serves files from a DocC archive.
public struct VaporDocCMiddleware: Middleware {
    /// The path to the DocC archive.
    public let archivePath: URL

    /// The path to redirect a request to the root (`/`) to. When `nil`,
    /// no redirection will occur.
    public let redirectRoot: String?

    /// When `true` the `/documentation` and `/tutorials` endpoints will
    /// be redirected to `/documentation/` and `/tutorials/` respectively.
    public let redirectMissingTrailingSlash: Bool

    /// The website prefix. If DocC supports being hosted outside
    /// of the root directory, this property will become public.
    private let prefix: String = "/"

    /// Create a new middleware that serves files from the DocC archive at ``archivePath``.
    ///
    /// When the ``redirectMissingTrailingSlash`` parameter is `true` the `/documentation` and `/tutorials`
    /// endpoints will be redirected to `/documentation/` and `/tutorials/` respectively.
    ///
    /// - Parameter archivePath: The path to the DocC archive.
    /// - Parameter redirectRoot: When non-`nil`, the root (`/`) will be redirected to the provided path. Defaults to `nil.`
    /// - Parameter redirectMissingTrailingSlash: When `true`, paths the require trailing slashes will be redirected to include the trailing slash. Defaults to `false`.
    public init(archivePath: URL, redirectRoot: String? = nil, redirectMissingTrailingSlash: Bool = false) {
        self.archivePath = archivePath
        self.redirectRoot = redirectRoot
        self.redirectMissingTrailingSlash = redirectMissingTrailingSlash
    }

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard var path = request.url.path.removingPercentEncoding else {
            return request.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        guard !path.contains("../") else {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        guard path.hasPrefix(self.prefix) else {
            return request.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        if path == self.prefix, let redirectRoot = redirectRoot {
            return request.eventLoop.makeSucceededFuture(
                request.redirect(to: redirectRoot)
            )
        }

        path = String(path.dropFirst(self.prefix.count))

        let indexPrefixes = [
            "documentation",
            "tutorials",
        ]

        for indexPrefix in indexPrefixes where path.hasPrefix(indexPrefix) {
            if indexPrefixes.contains(path) {
                // No trailing slash on request
                if redirectMissingTrailingSlash {
                    return request.eventLoop.makeSucceededFuture(
                        request.redirect(to: self.prefix + path + "/")
                    )
                } else {
                    return next.respond(to: request)
                }
            }

            return serveStaticFileRelativeToArchive("index.html", request: request)
        }

        if path == "data/documentation.json" {
            if FileManager.default.fileExists(atPath: archivePath.appendingPathComponent("data/documentation.json", isDirectory: true).path) {
                return serveStaticFileRelativeToArchive("data/documentation.json", request: request)
            }

            request.logger.info("\(self.prefix)data/documentation.json was not found; attempting to find product's JSON in /data/documentation/ directory")

            // The docs generated by Xcode 13.0 beta 1 request "/data/documentation.json" but the
            // generated archive puts this file under "/data/documentation/{product_name}.json".
            // Feedback logged under FB9156617.
            let documentationPath = archivePath.appendingPathComponent("data/documentation", isDirectory: true)
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: documentationPath.path)
                guard let productJSON = contents.first(where: { $0.hasSuffix(".json") }) else {
                    return next.respond(to: request)
                }

                return serveStaticFileRelativeToArchive("data/documentation/\(productJSON)", request: request)
            } catch {
                return next.respond(to: request)
            }
        }

        let staticFiles = [
            "favicon.ico",
            "favicon.svg",
            "theme-settings.json",
        ]

        for staticFile in staticFiles where path == staticFile {
            return serveStaticFileRelativeToArchive(staticFile, request: request)
        }

        let staticFilePrefixes = [
            "css/",
            "js/",
            "data/",
            "images/",
            "downloads/",
            "img/",
            "videos/",
        ]

        for staticFilePrefix in staticFilePrefixes where path.hasPrefix(staticFilePrefix) {
            return serveStaticFileRelativeToArchive(path, request: request)
        }

        return next.respond(to: request)
    }

    private func serveStaticFileRelativeToArchive(_ staticFilePath: String, request: Request) -> EventLoopFuture<Response> {
        let staticFileURL = archivePath.appendingPathComponent(staticFilePath, isDirectory: false)
        return request.eventLoop.makeSucceededFuture(
            request
                .fileio
                .streamFile(
                    at: staticFileURL.path
                )
        )
    }
}
