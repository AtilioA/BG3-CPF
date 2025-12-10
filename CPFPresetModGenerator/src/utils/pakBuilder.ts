// import FileSaver from 'file-saver';
import { loadPakWasm } from './loadPakWasm';
import JSZip from 'jszip';

/**
 * Packs the given files into a .pak using WASM.
 * @param files Array of files to pack, where content can be string or Uint8Array.
 * @returns The raw .pak file as a Uint8Array.
 */
export async function buildPak(files: { path: string; content: string | Uint8Array }[]): Promise<Uint8Array> {
    const wasm = await loadPakWasm();
    const { PakBuilder, ModFile, init_panic_hook } = wasm;

    init_panic_hook();
    const encoder = new TextEncoder();

    let builder: any = null;

    try {
        console.log("Files to pack:");

        const modFiles = files.map(file => {
            console.log("-", file.path, typeof file.content, (typeof file.content === "string") ? file.content.slice(0, 200) : `${file.content.length} bytes`);

            const contentEncoded =
                typeof file.content === "string"
                    ? encoder.encode(file.content)
                    : file.content;

            const modFile = new ModFile(file.path, contentEncoded);
            console.log(`Created ModFile: ${file.path}`);
            return modFile;
        });

        builder = new PakBuilder(modFiles);

        const packedData = builder.pack();
        console.log(`Packed .pak data size: ${packedData.length} bytes`);

        return packedData;

    } catch (error) {
        console.error("Error creating pak:", error);
        throw error;

    } finally {
        if (builder && typeof builder.free === 'function') {
            builder.free();
        }
    }
}

/**
 * Zips a .pak file.
 * @param pakData The raw .pak file data as a Uint8Array.
 * @param pakName The name of the .pak file inside the zip (e.g. "MyMod").
 * @returns A Blob containing the zipped .pak file.
 */
export async function zipPak(pakData: Uint8Array, pakName: string): Promise<Blob> {
    const zip = new JSZip();
    zip.file(`${pakName}.pak`, pakData);

    const zipBlob = await zip.generateAsync({ type: "blob" });
    console.log(`Zipped .pak file size: ${zipBlob.size} bytes`);

    return zipBlob;
}

/**
 * Builds a .pak file and zips it in one step.
 * This is a convenience function that composes buildPak and zipPak.
 * @param files Array of files to pack, where content can be string or Uint8Array.
 * @param pakName The name of the .pak file inside the zip (e.g. "MyMod").
 * @returns A Blob containing the zipped .pak file.
 */
export async function buildAndZipPak(files: { path: string; content: string | Uint8Array }[], pakName: string): Promise<Blob> {
    const pakData = await buildPak(files);
    return zipPak(pakData, pakName);
}
