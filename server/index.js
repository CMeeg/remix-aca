import { createRequestHandler } from "@remix-run/express"
import { installGlobals } from "@remix-run/node"
import express from "express"
import { useRewrite } from "./rewrite.js"
import { useRedirect } from "./redirect.js"
import { useCompression } from "./compression.js"
import { useSecurity } from "./security.js"
import { initAppInsights } from "./app-insights.js"
import { useLogging } from "./logging.js"

const mode = process.env.NODE_ENV
const isProductionMode = mode === "production"

const buildId = process.env.BUILD_ID
const isProductionBuild = !!buildId

if (!isProductionMode) {
  // Load .env file when not in production mode
  await import("dotenv").then((dotenv) => dotenv.config())
}

installGlobals()

const viteDevServer = isProductionMode
  ? undefined
  : await import("vite").then((vite) =>
      vite.createServer({
        server: { middlewareMode: true }
      })
    )

const getRequestHandler = async () => {
  const getLoadContext = (_, res) => {
    return { cspNonce: res.locals.cspNonce }
  }

  return createRequestHandler({
    build: viteDevServer
      ? () => viteDevServer.ssrLoadModule("virtual:remix/server-build")
      : await import("../build/server/index.js"),
    mode,
    getLoadContext
  })
}

const app = express()

// Trust the X-Forwarded-* headers set by Azure Container Apps in a production build
app.set("trust proxy", isProductionBuild)

const appInsights = initAppInsights()

app.use(appInsights.logRequests)

useRewrite(app)

useRedirect(app)

useCompression(app)

useSecurity(app)

useLogging(app)

// Handle asset requests
if (viteDevServer) {
  app.use(viteDevServer.middlewares)
} else {
  // Vite fingerprints its assets so we can cache forever
  app.use(
    "/assets",
    express.static("build/client/assets", { immutable: true, maxAge: "1y" })
  )
}

// Everything else (like favicon.ico) is cached for an hour. You may want to be more aggressive with this caching
app.use(express.static("build/client", { maxAge: "1h" }))

// Handle SSR requests
app.all("*", await getRequestHandler())

// Log errors to Application Insights
app.use(appInsights.logErrors)

const port = process.env.PORT ?? 3000
app.listen(port, () =>
  console.log(`Express server listening at http://localhost:${port}`)
)
