import { vitePlugin as remix } from "@remix-run/dev"
import { defineConfig } from "vite"
import tsconfigPaths from "vite-tsconfig-paths"

let base = process.env.CDN_URL ?? "/"
if (!base.endsWith("/")) {
  base = `${base}/`
}

export default defineConfig({
  base,
  plugins: [remix(), tsconfigPaths()]
})
