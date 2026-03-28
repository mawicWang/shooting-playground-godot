// Cloudflare Pages Worker
// Proxies index.wasm from R2 (42MB exceeds Pages 25MB file size limit)
// Also injects COOP/COEP headers required for Godot SharedArrayBuffer/threads

const R2_WASM_URL = 'https://pub-5da216c5c1864a1ba66ebc98a09e46ff.r2.dev/index.wasm';

const COOP_COEP_HEADERS = {
  'Cross-Origin-Opener-Policy': 'same-origin',
  'Cross-Origin-Embedder-Policy': 'require-corp',
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/index.wasm') {
      // Forward range requests (browser may stream WASM in chunks)
      const headers = {};
      const range = request.headers.get('Range');
      if (range) headers['Range'] = range;

      const r2Response = await fetch(R2_WASM_URL, {
        headers,
        cf: { cacheEverything: true, cacheTtl: 86400 },
      });

      const respHeaders = new Headers(r2Response.headers);
      for (const [k, v] of Object.entries(COOP_COEP_HEADERS)) {
        respHeaders.set(k, v);
      }

      return new Response(r2Response.body, {
        status: r2Response.status,
        headers: respHeaders,
      });
    }

    // Serve all other files from Pages static assets
    const response = await env.ASSETS.fetch(request);
    const respHeaders = new Headers(response.headers);
    for (const [k, v] of Object.entries(COOP_COEP_HEADERS)) {
      respHeaders.set(k, v);
    }

    return new Response(response.body, {
      status: response.status,
      headers: respHeaders,
    });
  },
};
