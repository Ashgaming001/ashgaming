// Vercel serverless proxy for SteamGridDB. Keep the API key server-side.
module.exports = async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store");
  if (req.method !== "GET") {
    res.setHeader("Allow", "GET");
    return res.status(405).json({ error: "Method not allowed" });
  }

  const apiKey = process.env.STEAMGRIDDB_API_KEY;
  if (!apiKey) return res.status(500).json({ error: "SteamGridDB API key is not configured in Vercel." });

  const name = String(req.query.name || "").trim().slice(0, 120);
  if (!name) return res.status(400).json({ error: "Missing game name." });

  const headers = { Authorization: "Bearer " + apiKey };
  const base = "https://www.steamgriddb.com/api/v2/";
  const normalize = value => String(value || "").toLowerCase().replace(/[^a-z0-9]/g, "");
  const clean = value => String(value || "").replace(/\\s*[:–—-]\\s*.+$/, "").trim();

  try {
    // Try the full title first, then a shorter base title for editions/subtitles.
    const queries = [...new Set([name, clean(name)].filter(Boolean))];
    const candidateMap = new Map();
    for (const query of queries) {
      const response = await fetch(base + "search/autocomplete/" + encodeURIComponent(query), { headers });
      if (!response.ok) {
        if (response.status === 401) {
          return res.status(502).json({ error: "SteamGridDB rejected the API key. Check the Vercel environment variable." });
        }
        continue;
      }
      const result = await response.json();
      for (const game of (Array.isArray(result.data) ? result.data : [])) {
        if (game && game.id) candidateMap.set(String(game.id), game);
      }
      if (candidateMap.size >= 12) break;
    }

    const candidates = [...candidateMap.values()];
    if (!candidates.length) return res.status(404).json({ error: "Game not found in SteamGridDB." });

    const wanted = normalize(name);
    candidates.sort((a, b) => {
      const score = game => {
        const title = normalize(game.name);
        if (title === wanted) return 0;
        if (title.startsWith(wanted) || wanted.startsWith(title)) return 1;
        if (title.includes(wanted) || wanted.includes(title)) return 2;
        return 3;
      };
      return score(a) - score(b);
    });

    // Check more candidate matches; some editions have a search result but no artwork.
    for (const game of candidates.slice(0, 10)) {
      const gridsResponse = await fetch(
        base + "grids/game/" + encodeURIComponent(game.id) + "?types=static&limit=50",
        { headers }
      );
      if (!gridsResponse.ok) continue;

      const grids = await gridsResponse.json();
      const artwork = Array.isArray(grids.data) ? grids.data : [];
      const portrait = artwork.filter(item => {
        const width = Number(item.width || 0);
        const height = Number(item.height || 0);
        return item.url && width > 0 && height > 0 && width / height >= 0.50 && width / height <= 0.90;
      });
      portrait.sort((a, b) => {
        const quality = item => {
          const ratio = Number(item.width) / Number(item.height);
          return Math.min(Number(item.width) * Number(item.height), 1000000) - Math.abs(ratio - 0.667) * 100000;
        };
        return quality(b) - quality(a);
      });
      const chosen = portrait[0] || artwork.find(item => item.url);
      if (chosen && chosen.url) {
        res.setHeader("Cache-Control", "public, s-maxage=86400, stale-while-revalidate=604800");
        return res.status(200).json({
          name: game.name,
          url: chosen.url,
          thumb: chosen.thumb || chosen.url
        });
      }
    }

    return res.status(404).json({ error: "No cover artwork is available for this game." });
  } catch (error) {
    return res.status(500).json({ error: "Poster lookup failed." });
  }
};
