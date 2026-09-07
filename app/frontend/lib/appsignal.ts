import Appsignal from "@appsignal/javascript";
import { plugin as windowEventsPlugin } from "@appsignal/plugin-window-events";

// Front-end error monitoring. The key is an ingest-only credential that is
// meant to be public, so app/views/layouts/spa.html.erb renders it into a meta
// tag rather than baking it into the bundle at build time — rotating it then
// needs no rebuild.
//
// Both tags are omitted when the credentials are unset (development, test, any
// self-hosted install without an AppSignal account), and `appsignal` stays
// null so nothing is reported and no network calls are attempted.

function metaContent(name: string): string | undefined {
  const tag = document.querySelector<HTMLMetaElement>(`meta[name="${name}"]`);
  return tag?.content || undefined;
}

function createClient(): Appsignal | null {
  const key = metaContent("appsignal-key");
  if (!key) return null;

  const client = new Appsignal({
    key,
    revision: metaContent("app-revision"),
    namespace: "frontend",
  });

  // Vue's errorHandler only sees errors thrown inside components. Nearly
  // everything this app does is an awaited API call, so without this the
  // rejections that matter most would go unreported.
  client.use(windowEventsPlugin());

  return client;
}

export const appsignal = createClient();
