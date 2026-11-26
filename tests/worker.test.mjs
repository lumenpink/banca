import test from "node:test";
import assert from "node:assert/strict";
import { resolveRoute } from "../src/worker.js";

test("pratilera.2lp.in proxies root to index-v1.json and APKs to bucket /pratilera/", () => {
  assert.deepEqual(resolveRoute("https://pratilera.2lp.in/"), {
    kind: "proxy",
    upstream: "https://bucket.2lp.in/pratilera/index-v1.json",
    fallbackAssetPath: "/pratilera/index-v1.json",
  });

  assert.deepEqual(resolveRoute("https://pratilera.2lp.in/mocambo.apk"), {
    kind: "proxy",
    upstream: "https://bucket.2lp.in/pratilera/mocambo.apk",
    fallbackAssetPath: "/pratilera/mocambo.apk",
  });

  assert.deepEqual(resolveRoute("https://pratilera.2lp.in/icons/in.twolp.mocambo.png"), {
    kind: "proxy",
    upstream: "https://bucket.2lp.in/pratilera/icons/in.twolp.mocambo.png",
    fallbackAssetPath: "/pratilera/icons/in.twolp.mocambo.png",
  });
});

test("banca.2lp.in/pratilera/* proxies to bucket /pratilera/* and aliases redirect", () => {
  assert.deepEqual(resolveRoute("https://banca.2lp.in/pratilera/mocambo.apk"), {
    kind: "proxy",
    upstream: "https://bucket.2lp.in/pratilera/mocambo.apk",
    fallbackAssetPath: "/pratilera/mocambo.apk",
  });

  assert.deepEqual(resolveRoute("https://banca.2lp.in/patilera"), {
    kind: "redirect",
    location: "https://banca.2lp.in/pratilera/",
    status: 301,
  });

  assert.deepEqual(resolveRoute("https://banca.2lp.in/downloads/lauda/nightly/lauda.tar.gz"), {
    kind: "redirect",
    location: "https://bucket.2lp.in/downloads/lauda/nightly/lauda.tar.gz",
    status: 302,
  });

  assert.deepEqual(resolveRoute("https://banca.2lp.in/"), { kind: "asset" });
});
