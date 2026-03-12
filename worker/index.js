// Cloudflare Worker: serves speedtest.ps1 or speedtest.sh at speed.it2.sh
// OS is detected from the User-Agent header.
//
// Windows (PowerShell):  irm speed.it2.sh | iex
// Linux/macOS (bash):    curl -sL speed.it2.sh | bash

const SCRIPTS = {
  ps1: "https://github.com/TheTechNetwork/speedtest-pwsh/releases/latest/download/speedtest.ps1",
  sh:  "https://github.com/TheTechNetwork/speedtest-pwsh/releases/latest/download/speedtest.sh",
};

function detectOS(userAgent) {
  if (!userAgent) return "unknown";
  const ua = userAgent.toLowerCase();
  if (ua.includes("windows") || ua.includes("powershell")) return "windows";
  if (ua.includes("darwin") || ua.includes("mac")) return "macos";
  if (ua.includes("linux")) return "linux";
  return "unknown";
}

export default {
  async fetch(request) {
    const url = new URL(request.url);

    // Health check
    if (url.pathname === "/health") {
      return new Response("OK", { status: 200 });
    }

    const ua = request.headers.get("User-Agent") || "";
    const os = detectOS(ua);

    // Windows → PowerShell script; Linux/macOS/unknown → bash script
    const scriptUrl = os === "windows" ? SCRIPTS.ps1 : SCRIPTS.sh;
    const scriptName = os === "windows" ? "speedtest.ps1" : "speedtest.sh";

    const response = await fetch(scriptUrl, {
      headers: {
        "User-Agent": "speedtest-worker/1.0",
        Accept: "application/octet-stream",
      },
      redirect: "follow",
    });

    if (!response.ok) {
      return new Response(
        `Failed to fetch ${scriptName}: ${response.statusText}`,
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
        "X-Script": scriptName,
        "X-Detected-OS": os,
      },
    });
  },
};
