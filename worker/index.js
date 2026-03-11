// Cloudflare Worker: serves speedtest.ps1 at speed.it2.sh
// Users run: irm speed.it2.sh | iex

const GITHUB_RAW_URL =
  "https://github.com/asheroto/speedtest/releases/latest/download/speedtest.ps1";

export default {
  async fetch(request) {
    const url = new URL(request.url);

    // Health check
    if (url.pathname === "/health") {
      return new Response("OK", { status: 200 });
    }

    // Fetch the latest release of speedtest.ps1 from GitHub and proxy it
    const response = await fetch(GITHUB_RAW_URL, {
      headers: {
        "User-Agent": "speedtest-worker/1.0",
        Accept: "application/octet-stream",
      },
      redirect: "follow",
    });

    if (!response.ok) {
      return new Response(
        `Failed to fetch speedtest.ps1: ${response.statusText}`,
        { status: 502 }
      );
    }

    const body = await response.text();

    return new Response(body, {
      status: 200,
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "public, max-age=3600",
        "X-Source": "speed.it2.sh",
      },
    });
  },
};
