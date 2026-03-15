export default {
  async fetch(request) {
    const url = new URL(request.url);
    url.hostname = 'pdftyping.pages.dev';
    const proxied = new Request(url.toString(), {
      method: request.method,
      headers: request.headers,
      body: request.method === 'GET' || request.method === 'HEAD' ? undefined : request.body,
      redirect: 'follow',
    });
    return fetch(proxied);
  },
};
