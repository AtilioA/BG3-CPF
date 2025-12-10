export async function loadPakWasm() {
    const wasm = await import("larian-formats");
    await wasm.default();
    return wasm;
}
