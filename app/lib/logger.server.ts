import pino from "pino"
import { environment } from "~/lib/env.server"

const createLogger = () => {
  const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING

  if (connectionString) {
    const transport = pino.transport({
      targets: [
        {
          level: process.env.MIN_LOG_LEVEL,
          target: "@0dep/pino-applicationinsights",
          options: {
            connectionString
          }
        }
      ]
    })

    return pino(transport)
  }

  if (process.env.NODE_ENV === environment.development) {
    // Create a pino logger instance using the pino-pretty transport
    const transport = pino.transport({
      target: "pino-pretty",
      options: {
        minumumLevel: process.env.MIN_LOG_LEVEL
      }
    })

    return pino(transport)
  }

  // Create a pino logger instance using the default transport
  return pino({
    level: process.env.MIN_LOG_LEVEL
  })
}

const logger = createLogger()

export { logger }
