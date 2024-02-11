import rewrite from "express-urlrewrite"

export function useRewrite(app) {
  // Rewrite paths that start with the build ID to remove the build ID (used for cache busting)
  const buildId = process.env.BUILD_ID
  if (buildId) {
    app.use(rewrite(`/${buildId}/*`, "/$1"))
  }
}
