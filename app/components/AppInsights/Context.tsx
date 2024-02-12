import type { FC, ReactNode } from "react"
import { ApplicationInsights } from "@microsoft/applicationinsights-web"
import type {
  IEventTelemetry,
  IMetricTelemetry,
  IExceptionTelemetry,
  ICustomProperties
} from "@microsoft/applicationinsights-web"
import {
  ReactPlugin,
  AppInsightsContext,
  useAppInsightsContext
} from "@microsoft/applicationinsights-react-js"

declare const window: {
  __APP_INSIGHTS__?: ReactPlugin
} & Window

// Store the AI instance on `window` so we aren't constantly re-initializing it on every hot-reload during `npm run dev` (we can't use a `Symbol` for this, as we'd get a new symbol on every hot-reload)
const getAppInsightsInstance = () =>
  (typeof document !== "undefined" && window.__APP_INSIGHTS__) || undefined

const setAppInsightsInstance = (appInsights: ReactPlugin) => {
  if (typeof document !== "undefined") {
    window.__APP_INSIGHTS__ = appInsights
  }
}

const loadAppInsights = (connectionString: string) => {
  let reactPlugin = getAppInsightsInstance()

  if (reactPlugin) {
    return reactPlugin
  }

  reactPlugin = new ReactPlugin()

  const appInsights = new ApplicationInsights({
    config: {
      connectionString,
      enableAutoRouteTracking: true,
      disablePageUnloadEvents: ["unload"],
      extensions: [reactPlugin]
    }
  })

  appInsights.loadAppInsights()

  setAppInsightsInstance(reactPlugin)

  return reactPlugin
}

interface AppInsightsContextProviderProps {
  connectionString: string
  children: ReactNode
}

const AppInsightsContextProvider: FC<AppInsightsContextProviderProps> = ({
  connectionString,
  children
}) => {
  const reactPlugin = loadAppInsights(connectionString)

  return (
    <AppInsightsContext.Provider value={reactPlugin}>
      {children}
    </AppInsightsContext.Provider>
  )
}

const useTrackEvent = (
  event: IEventTelemetry,
  customProperties?: ICustomProperties
) => {
  const appInsights = useAppInsightsContext()

  if (!appInsights) {
    return
  }

  appInsights.trackEvent(event, customProperties)
}

const useTrackMetric = (
  metric: IMetricTelemetry,
  customProperties: ICustomProperties
) => {
  const appInsights = useAppInsightsContext()

  if (!appInsights) {
    return
  }

  appInsights.trackMetric(metric, customProperties)
}

const useTrackException = (
  exception: IExceptionTelemetry,
  customProperties?: ICustomProperties
) => {
  const appInsights = useAppInsightsContext()

  if (!appInsights) {
    return
  }

  return appInsights.trackException(exception, customProperties)
}

export default AppInsightsContextProvider

export { useTrackEvent, useTrackMetric, useTrackException }

export type { AppInsightsContextProviderProps }
