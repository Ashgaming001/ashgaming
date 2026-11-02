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

  try {
    const searchResponse = await fetch(base + "search/autocomplete/" + encodeURIComponent(name), { headers });
    if (!searchResponse.ok) {
      return res.status(searchResponse.status === 401 ? 502 : searchResponse.status)
        .json({ error: searchResponse.status === 401 ? "SteamGridDB rejected the API key. Check the Vercel environment variable." : "SteamGridDB game search failed." });
    }

    const search = await searchResponse.json();
    const candidates = Array.isArray(search.data) ? search.data : [];
    if (!candidates.length) return res.status(404).json({ error: "Game not found in SteamGridDB." });

    const wanted = normalize(name);
    candidates.sort((a, b) => {
      const score = game => {
        const title = normalize(game.name);
        if (title === wanted) return 0;
        if (title.startsWith(wanted)) return 1;
        if (title.includes(wanted) || wanted.includes(title)) return 2;
        return 3;
      };
      return score(a) - score(b);
    });

    // Do not force one exact image resolution: many valid covers use other
    // supported portrait sizes (for example 342x482 or 660x930).
    for (const game of candidates.slice(0, 4)) {
      const gridsResponse = await fetch(
        base + "grids/game/" + encodeURIComponent(game.id) + "?types=static&limit=20",
        { headers }
      );
      if (!gridsResponse.ok) continue;

      const grids = await gridsResponse.json();
      const artwork = Array.isArray(grids.data) ? grids.data : [];
      const portrait = artwork.filter(item => {
        const width = Number(item.width || 0);
        const height = Number(item.height || 0);
        return width > 0 && height > 0 && width / height >= 0.52 && width / height <= 0.88;
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

    return res.status(404).json({ error: "No portrait cover is available for this game." });
  } catch (error) {
    return res.status(500).json({ error: "Poster lookup failed." });
  }
};
