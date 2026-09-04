// A server-rendered screen hands the login the path it turned the visitor
// away from. It arrives as a query param, which anyone can write, so it is
// only usable if it points back at this app: one leading slash, and not the
// two that would make it a url on someone else's host.
export function safeReturnPath(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined
  if (!value.startsWith("/") || value.startsWith("//")) return undefined
  // `/\evil.com` is read as a host by some browsers.
  if (value.startsWith("/\\")) return undefined

  return value
}
