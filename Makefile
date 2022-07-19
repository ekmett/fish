ARCH=x86_64-apple-darwin
# ARCH=aarch64-apple-darwin
LLI=/Users/ekmett/.sdkman/candidates/java/current/bin/lli

TARGET_BC=target/$(ARCH)/release/deps/fish.bc

go: run-unverified

all: fish.bc

clean:
	rm -rf target

lib: $(TARGET_BC)

target:
	mkdir -p target

$(TARGET_BC): $(wildcard src/*.rs)
	cargo rustc --target=$(ARCH) --release --lib -- --emit=llvm-bc

target/fish.bc: target/stub.bc $(TARGET_BC)
	llvm-link target/stub.bc $(TARGET_BC) -o=target/fish.bc

target/stub.ll: src/stub.c target
	clang --target=$(ARCH) src/stub.c -S -emit-llvm -o target/stub.ll

target/stub.bc: target/stub.ll
	llvm-as target/stub.ll -o=target/stub.bc

run-unverified: target/fish.bc
	$(LLI) --experimental-options --llvm.verifyBitcode=false --lib `rustc --print sysroot`/lib/libstd-* target/fish.bc

run: target/fish.bc
	$(LLI) --lib `rustc --print sysroot`/lib/libstd-* target/fish.bc

.PHONY: clean run all run-unverified go lib
