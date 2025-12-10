/* tslint:disable */
/* eslint-disable */

export class ModFile {
  free(): void;
  [Symbol.dispose](): void;
  constructor(path: string, contents: Uint8Array);
}

export class PakBuilder {
  free(): void;
  [Symbol.dispose](): void;
  constructor(files?: ModFile[] | null);
  add_file(path: string, contents: Uint8Array): void;
  pack(): Uint8Array;
}

export function init_panic_hook(): void;

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
  readonly memory: WebAssembly.Memory;
  readonly init_panic_hook: () => void;
  readonly __wbg_modfile_free: (a: number, b: number) => void;
  readonly modfile_new: (a: number, b: number, c: number, d: number) => number;
  readonly __wbg_pakbuilder_free: (a: number, b: number) => void;
  readonly pakbuilder_new: (a: number, b: number) => number;
  readonly pakbuilder_add_file: (a: number, b: number, c: number, d: number, e: number) => void;
  readonly pakbuilder_pack: (a: number) => [number, number, number, number];
  readonly __wbindgen_free: (a: number, b: number, c: number) => void;
  readonly __wbindgen_malloc: (a: number, b: number) => number;
  readonly __wbindgen_realloc: (a: number, b: number, c: number, d: number) => number;
  readonly __wbindgen_externrefs: WebAssembly.Table;
  readonly __externref_table_alloc: () => number;
  readonly __externref_table_dealloc: (a: number) => void;
  readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;

/**
* Instantiates the given `module`, which can either be bytes or
* a precompiled `WebAssembly.Module`.
*
* @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
*
* @returns {InitOutput}
*/
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
* If `module_or_path` is {RequestInfo} or {URL}, makes a request and
* for everything else, calls `WebAssembly.instantiate` directly.
*
* @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
*
* @returns {Promise<InitOutput>}
*/
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
