import { getEnv } from "./env"

const joinUrlSegments = (segments?: string[] | null) => {
  if (!segments || segments.length === 0) {
    return ""
  }

  const lastSegmentIndex = segments.length - 1

  const urlSegments = segments.map((segment, index) => {
    let urlSegment =
      index > 0 && segment.startsWith("/") ? segment.slice(1) : segment

    urlSegment =
      index < lastSegmentIndex && urlSegment.endsWith("/")
        ? urlSegment.slice(0, -1)
        : urlSegment

    return urlSegment
  })

  return urlSegments.join("/")
}

const getAbsoluteUrl = (path?: string) => {
  const env = getEnv()
  const baseUrl = env.BASE_URL

  if (!path) {
    return baseUrl
  }

  return joinUrlSegments([baseUrl, path])
}

const getCdnUrl = (path?: string, includeFingerprint = true) => {
  const env = getEnv()
  const baseCdnUrl = env.CDN_URL

  if (!baseCdnUrl) {
    return path ?? ""
  }

  if (!path) {
    return baseCdnUrl
  }

  const buildId = env.BUILD_ID

  if (includeFingerprint && buildId) {
    return joinUrlSegments([baseCdnUrl, buildId, path])
  }

  return joinUrlSegments([baseCdnUrl, path])
}

export { getAbsoluteUrl, getCdnUrl }
