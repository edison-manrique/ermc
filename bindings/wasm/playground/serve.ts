/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * serve.ts — Servidor local de desarrollo para el Playground WebAssembly ERMC
 * Uso: bun run bindings/wasm/playground/serve.ts
 */

import { join, dirname } from "path"
import { fileURLToPath } from "url"
import { existsSync, readFileSync } from "fs"

const PORT = 3000
const DIR = dirname(fileURLToPath(import.meta.url))

const server = Bun.serve({
  port: PORT,
  fetch(req) {
    const url = new URL(req.url)
    let path = url.pathname === "/" ? "/index.html" : url.pathname
    const fullPath = join(DIR, path)

    if (existsSync(fullPath)) {
      const file = Bun.file(fullPath)
      // Asignar tipo MIME correcto para WebAssembly y JavaScript
      const headers: Record<string, string> = {}
      if (path.endsWith(".wasm")) {
        headers["Content-Type"] = "application/wasm"
      } else if (path.endsWith(".js")) {
        headers["Content-Type"] = "application/javascript"
      } else if (path.endsWith(".css")) {
        headers["Content-Type"] = "text/css"
      } else if (path.endsWith(".html")) {
        headers["Content-Type"] = "text/html; charset=utf-8"
      }
      return new Response(file, { headers })
    }

    return new Response("404 Not Found", { status: 404 })
  }
})

console.log("\n========================================================")
console.log("  ⚡ ERMC WebAssembly Playground Servidor Activo")
console.log(`  🌐 Abre en tu navegador: http://localhost:${server.port}`)
console.log("========================================================\n")
