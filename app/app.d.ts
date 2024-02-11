import "@remix-run/node"

declare module "@remix-run/node" {
  export interface AppLoadContext {
    cspNonce?: string
  }
}
