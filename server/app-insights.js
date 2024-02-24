import appInsights from "applicationinsights"
import { v4 as uuid } from "uuid"

export function initAppInsights() {
  const connectionString =
    process.env.APPLICATIONINSIGHTS_CONNECTION_STRING ?? ""

  if (!connectionString) {
    return {
      client: undefined,
      // no-op
      logRequests: (_, __, next) => next(),
      // no-op
      logErrors: (_, __, ___, next) => next()
    }
  }

  appInsights
    .setup(connectionString)
    .setAutoCollectRequests(false)
    .setAutoCollectExceptions(false)
    .setSendLiveMetrics(true)

  appInsights.defaultClient.config.samplingPercentage = 80

  appInsights.start()

  const client = appInsights.defaultClient

  const logRequests = (req, res, next) => {
    res.locals.appInsights = client
    res.locals.requestId = uuid()

    client.trackNodeHttpRequest({
      request: req,
      response: res,
      properties: { requestId: res.locals.requestId }
    })

    next()
  }

  const logErrors = (err, req, res, next) => {
    client.trackException({
      exception: err,
      properties: {
        url: req.url,
        requestId: res.locals.requestId
      }
    })

    next(err)
  }

  return {
    client,
    logRequests,
    logErrors
  }
}
