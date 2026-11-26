const BUCKET_ORIGIN = "https://bucket.2lp.in";
const ALIAS_PREFIXES = ["/patilera", "/prateleira", "/repo"];

/**
 * Resolve o destino de roteamento para `pratilera.2lp.in` e `banca.2lp.in`.
 * Retorna `{ kind: "redirect", location, status }`, `{ kind: "proxy", upstream, fallbackAssetPath }`
 * ou `{ kind: "asset" }`.
 */
export function resolveRoute(urlString) {
  const url = new URL(urlString);
  const path = url.pathname;

  if (url.hostname === "pratilera.2lp.in") {
    const normalized = path.startsWith("/pratilera/")
      ? path.slice("/pratilera".length)
      : path === "/pratilera"
        ? "/"
        : path;
    const subPath = normalized === "/" || normalized === "" ? "/index-v1.json" : normalized;
    return {
      kind: "proxy",
      upstream: `${BUCKET_ORIGIN}/pratilera${subPath}`,
      fallbackAssetPath: `/pratilera${subPath}`,
    };
  }

  for (const prefix of ALIAS_PREFIXES) {
    if (path === prefix || path === `${prefix}/`) {
      return { kind: "redirect", location: `${url.origin}/pratilera/`, status: 301 };
    }
    if (path.startsWith(`${prefix}/`)) {
      const rest = path.slice(prefix.length);
      return { kind: "redirect", location: `${url.origin}/pratilera${rest}`, status: 301 };
    }
  }

  if (path.startsWith("/downloads/")) {
    return { kind: "redirect", location: `${BUCKET_ORIGIN}${path}${url.search}`, status: 302 };
  }

  if (path.startsWith("/pratilera/") && path.length > "/pratilera/".length) {
    return {
      kind: "proxy",
      upstream: `${BUCKET_ORIGIN}${path}`,
      fallbackAssetPath: path,
    };
  }

  return { kind: "asset" };
}

export default {
  async fetch(request, env) {
    const route = resolveRoute(request.url);

    if (route.kind === "redirect") {
      return Response.redirect(route.location, route.status);
    }

    if (route.kind === "proxy") {
      const upstreamReq = new Request(route.upstream, {
        method: request.method,
        headers: request.headers,
      });
      const upstreamRes = await fetch(upstreamReq);
      if (upstreamRes.status !== 404 || !env?.ASSETS) {
        return upstreamRes;
      }
      const assetUrl = new URL(request.url);
      assetUrl.pathname = route.fallbackAssetPath;
      return env.ASSETS.fetch(new Request(assetUrl.toString(), request));
    }

    return env.ASSETS.fetch(request);
  },
};
