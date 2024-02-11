import morgan from "morgan"

export function useLogging(app) {
  const isProductionMode = process.env.NODE_ENV === "production"

  // Http logging
  app.use(morgan(isProductionMode ? "common" : "dev"))
}
