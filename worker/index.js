// Cloudflare Worker: serves speedtest.ps1 or speedtest.sh at speed.it2.sh
// OS is detected from the User-Agent header.
//
// Windows (PowerShell):  irm speed.it2.sh | iex
// Linux/macOS (bash):    curl -sL speed.it2.sh | bash

function detectOS(userAgent) {
  if (!userAgent) return "unknown";
  const ua = userAgent.toLowerCase();
  if (ua.includes("windows") || ua.includes("powershell")) return "windows";
  if (ua.includes("darwin") || ua.includes("mac")) return "macos";
  if (ua.includes("linux")) return "linux";
  return "unknown";
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Health check
    if (url.pathname === "/health") {
      return new Response("OK", { status: 200 });
    }

    const ua = request.headers.get("User-Agent") || "";
    const os = detectOS(ua);

    // Windows → PowerShell script; Linux/macOS/unknown → bash script
    const scriptName = os === "windows" ? "speedtest.ps1" : "speedtest.sh";

    // Serve the file directly from the uploaded assets
    const assetResponse = await env.ASSETS.fetch(
      new Request(`https://assets.local/${scriptName}`)
    );

    if (!assetResponse.ok) {
      return new Response(`Failed to load ${scriptName}`, { status: 502 });
    }

    const body = await assetResponse.text();

    return new Response(body, {
      status: 200,
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "public, max-age=3600",
        "X-Source": "speed.it2.sh",
        "X-Script": scriptName,
        "X-Detected-OS": os,
      },
    });
  },
};
