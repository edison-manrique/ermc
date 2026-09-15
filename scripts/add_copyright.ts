/**
 * Script de automatización para aplicar encabezados de Copyright y Licencia Dual
 * Autor: Edison Manrique Chocce
 * 
 * Escanea recursivamente los archivos fuente (.zig, .ts) y aplica el bloque
 * de copyright al inicio del archivo si no está presente.
 */

import { readdirSync, statSync, readFileSync, writeFileSync, existsSync } from "fs";
import { join, extname } from "path";

const COPYRIGHT_HOLDER = "Edison Manrique Chocce";
const YEAR = "2026";

const ZIG_HEADER = `// Copyright (c) ${YEAR} ${COPYRIGHT_HOLDER}
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

`;

const TS_HEADER = `/**
 * Copyright (c) ${YEAR} ${COPYRIGHT_HOLDER}
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

`;

const TARGET_DIRECTORIES = ["src", "tests", "examples", "bindings/bun"];
const SINGLE_FILES = ["build.zig"];

const ROOT_DIR = join(import.meta.dir, "..");

let modifiedCount = 0;
let skippedCount = 0;

function processFile(filePath: string) {
  const ext = extname(filePath);
  if (ext !== ".zig" && ext !== ".ts") return;

  const content = readFileSync(filePath, "utf-8");

  // Si ya tiene el copyright, saltar
  if (content.includes("Edison Manrique Chocce") || content.includes("Copyright (c)")) {
    console.log(`[OMITIDO] Ya tiene copyright: ${filePath}`);
    skippedCount++;
    return;
  }

  const header = ext === ".zig" ? ZIG_HEADER : TS_HEADER;
  writeFileSync(filePath, header + content, "utf-8");
  console.log(`[APLICADO] Copyright añadido a: ${filePath}`);
  modifiedCount++;
}

function scanDir(dirPath: string) {
  if (!existsSync(dirPath)) return;
  const entries = readdirSync(dirPath);

  for (const entry of entries) {
    // Ignorar caches, dependencias y builds
    if (entry === "node_modules" || entry === ".zig-cache" || entry === "zig-out") continue;

    const fullPath = join(dirPath, entry);
    const stat = statSync(fullPath);

    if (stat.isDirectory()) {
      scanDir(fullPath);
    } else if (stat.isFile()) {
      processFile(fullPath);
    }
  }
}

console.log("=========================================================================");
console.log(`  APLICADOR DE COPYRIGHT Y LICENCIA DUAL: ${COPYRIGHT_HOLDER}`);
console.log("=========================================================================");

// Procesar archivos individuales en la raíz
for (const file of SINGLE_FILES) {
  const fullPath = join(ROOT_DIR, file);
  if (existsSync(fullPath)) {
    processFile(fullPath);
  }
}

// Procesar directorios destino
for (const targetDir of TARGET_DIRECTORIES) {
  scanDir(join(ROOT_DIR, targetDir));
}

console.log("-------------------------------------------------------------------------");
console.log(`Total archivos actualizados: ${modifiedCount}`);
console.log(`Total archivos ya protegidos / omitidos: ${skippedCount}`);
console.log("=========================================================================");
