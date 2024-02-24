import { z } from "zod"

const environment = {
  development: "development",
  production: "production"
} as const

type Environment = keyof typeof environment

const processEnvSchema = z.object({
  NODE_ENV: z.enum(["production", "development", "test"] as const),
  APP_ENV: z.string(),
  APPLICATIONINSIGHTS_CONNECTION_STRING: z.string().optional(),
  BASE_URL: z.string().url(),
  BUILD_ID: z.string().optional(),
  CDN_URL: z.string().optional(),
  MIN_LOG_LEVEL: z.string().optional()
})

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace NodeJS {
    interface ProcessEnv extends z.infer<typeof processEnvSchema> {}
  }
}

const parseProcessEnv = () => {
  const parsed = processEnvSchema.safeParse(process.env)

  if (parsed.success === false) {
    console.error(
      "❌ Invalid environment variables:",
      parsed.error.flatten().fieldErrors
    )

    throw new Error("Invalid environment variables")
  }
}

const appEnvironment = process.env.APP_ENV

const getCurrentEnvironment = () => {
  if (!appEnvironment) {
    // Default to development if no appEnvironment is set
    return environment.development
  }

  const currentAppEnv = environment[appEnvironment as Environment]

  if (typeof currentAppEnv !== "undefined") {
    // appEnvironment is a valid environment
    return currentAppEnv
  }

  if (appEnvironment.startsWith("prod")) {
    // appEnvironment is an alias for production
    return environment.production
  }

  // Default to development
  return environment.development
}

const currentEnvironment = getCurrentEnvironment()

/**
 * This is used in both `entry.server.ts` and `root.tsx` to ensure that
 * the environment variables are set and globally available before the app is
 * started.
 *
 * NOTE: Do *not* add any environment variables in here that you do not wish to
 * be included in the client.
 * @returns all public ENV variables
 */
const getClientEnv = () => {
  return {
    APPLICATIONINSIGHTS_CONNECTION_STRING:
      process.env.APPLICATIONINSIGHTS_CONNECTION_STRING
  }
}

type ClientEnv = ReturnType<typeof getClientEnv>

declare global {
  // eslint-disable-next-line no-var
  var ENV: ClientEnv
}

export { parseProcessEnv, getClientEnv, environment, currentEnvironment }

export type { Environment }
