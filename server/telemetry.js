import { metrics, trace } from "@opentelemetry/api"
import { useAzureMonitor } from "@azure/monitor-opentelemetry"
import { Resource } from "@opentelemetry/resources"
import { SemanticResourceAttributes } from "@opentelemetry/semantic-conventions"
import { registerInstrumentations } from "@opentelemetry/instrumentation"
import { ExpressInstrumentation } from "@opentelemetry/instrumentation-express"
import { RemixInstrumentation } from "opentelemetry-instrumentation-remix"
import { PinoInstrumentation } from "@opentelemetry/instrumentation-pino"

const initTelemetry = () => {
  //const connectionString = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING
  const connectionString =
    "InstrumentationKey=7b5f5390-48c9-4220-a053-d8dd25d0ee3c;IngestionEndpoint=https://westeurope-5.in.applicationinsights.azure.com/;LiveEndpoint=https://westeurope.livediagnostics.monitor.azure.com/"

  if (!connectionString) {
    return
  }

  // Get the OpenTelemetry tracer provider and meter provider

  const resource = new Resource({
    // TODO: Get these from env vars?
    [SemanticResourceAttributes.SERVICE_NAME]: "web-app",
    [SemanticResourceAttributes.SERVICE_NAMESPACE]: "remix-aca"
    // TODO: Anything we can use from ACA?
    //[SemanticResourceAttributes.SERVICE_INSTANCE_ID]: "my-instance"
  })

  const tracerProvider = trace.getTracerProvider().getDelegate()
  const meterProvider = metrics.getMeterProvider()

  // Enable Azure Monitor integration
  // https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable?tabs=nodejs
  useAzureMonitor({
    azureMonitorExporterOptions: {
      connectionString
    },
    resource,
    samplingRatio: 1,
    instrumentationOptions: {
      http: { enabled: true },
      azureSdk: { enabled: true },
      mongoDb: { enabled: false },
      mySql: { enabled: false },
      postgreSql: { enabled: false },
      redis: { enabled: false },
      redis4: { enabled: false },
      bunyan: { enabled: false }
    }
  })

  // Register additional instrumentations
  // https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-add-modify
  registerInstrumentations({
    instrumentations: [
      // Express instrumentation expects HTTP layer to be instrumented
      // TODO: Azure Monitor adds http instrumentation so we don't need this?
      //new HttpInstrumentation(),
      new ExpressInstrumentation(),
      new RemixInstrumentation(),
      new PinoInstrumentation()
    ],
    tracerProvider,
    meterProvider
  })
}

//initTelemetry()

export { initTelemetry }
