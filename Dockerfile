# ================================
# Build image
# ================================
FROM vapor/swift:5.2.2 as build
WORKDIR /app

# Copy entire repo into container
COPY . .

# Add dependencies to image
RUN apt-get update && apt-get install -y \
    openssl \
		libssl-dev \
		zlib1g

# Compile with optimizations
RUN swift build \
	--enable-test-discovery \
	-c release \
	-Xswiftc -g

# ================================
# Run image
# ================================
FROM swift:5.2.2
WORKDIR /run

# Copy build artifacts
COPY --from=build /app/.build/release /run

ENTRYPOINT ["./Run"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--log", "debug"]
