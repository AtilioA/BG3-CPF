// import FileSaver from 'file-saver';
import { loadPakWasm } from './loadPakWasm';
import JSZip from 'jszip';

/**
 * Packs the given files into a .pak using WASM and then zips it.
 * @param files Array of files to pack, where content can be string or Uint8Array.
 * @param pakName The name of the resulting .pak file inside the zip (e.g. "MyMod").
 * @returns The zipped byte array.
 */
export async function buildPak(files: { path: string; content: string | Uint8Array }[], pakName: string = "Mod"): Promise<void> {
    const wasm = await loadPakWasm();
    const { PakBuilder, ModFile, init_panic_hook } = wasm;

    init_panic_hook();
    const encoder = new TextEncoder();

    try {
        console.log("Files to pack:");

        // Create ModFile instances
        const modFiles = files.map(file => {
            console.log("-", file.path, typeof file.content, (typeof file.content === "string") ? file.content.slice(0, 200) : `${file.content.length} bytes`);

            let contentEncoded: Uint8Array;
            const content = file.content;
            if (typeof content === 'string') {
                contentEncoded = encoder.encode(content);
            } else {
                contentEncoded = content;
            }

            const modFile = new ModFile(file.path, contentEncoded);
            console.log(`Created ModFile: ${file.path}`);
            return modFile;
        });

        const builder = new PakBuilder(modFiles);

        // Erroring here
        const packedData = builder.pack();
        console.log(`Packed data size: ${packedData.length}`);

        // } finally {
        //     if (builder && typeof builder.free === 'function') {
        //         builder.free();
        //     }
    }
    catch (error) {
        console.error("Error creating pak:", error);
        throw error;
    }
}
