FROM moonbit-qemu

WORKDIR /app
COPY . .

RUN moon update
RUN moon build --target wasm-gc --release --no-strip
