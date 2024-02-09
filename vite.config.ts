import { unstable_vitePlugin as remix } from "@remix-run/dev"
import { defineConfig } from "vite"
import tsconfigPaths from "vite-tsconfig-paths"

let publicPath = process.env.CDN_URL ?? "/"
if (!publicPath.endsWith("/")) {
  publicPath = `${publicPath}/`
}

export default defineConfig({
  plugins: [
    remix({
      publicPath
    }),
    tsconfigPaths()
  ]
})
