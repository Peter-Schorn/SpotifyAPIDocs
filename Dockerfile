FROM swift:5.5 as builder

WORKDIR /build

COPY Sources Sources
COPY Tests Tests
COPY Package.swift Package.swift
COPY Package.resolved Package.resolved

RUN swift package resolve
RUN swift build --product Run --configuration debug --enable-test-discovery
RUN ln -s `swift build --configuration debug --show-bin-path` /build/bin

FROM swift:5.5

RUN mkdir /app
COPY --from=builder /build/bin/Run /app/Run
EXPOSE 8080
CMD /app/Run
