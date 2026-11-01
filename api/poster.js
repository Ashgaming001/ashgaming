// Vercel serverless proxy for SteamGridDB. Keep the API key server-side.
module.exports = async function handler(req, res) {
  res.setHeader("Cache-Control", "s-maxage=86400, stale-while-revalidate=604800");
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

  try {
    const searchResponse = await fetch(base + "search/autocomplete/" + encodeURIComponent(name), { headers });
    if (!searchResponse.ok) {
      return res.status(searchResponse.status === 401 ? 502 : searchResponse.status)
        .json({ error: searchResponse.status === 401 ? "SteamGridDB rejected the API key. Check the Vercel environment variable." : "SteamGridDB game search failed." });
    }
    const search = await searchResponse.json();
    const candidates = Array.isArray(search.data) ? search.data : [];
    if (!candidates.length) return res.status(404).json({ error: "Game not found in SteamGridDB." });

    const normalize = value => String(value || "").toLowerCase().replace(/[^a-z0-9]/g, "");
    const wanted = normalize(name);
    const match = candidates.find(game => normalize(game.name) === wanted)
      || candidates.find(game => normalize(game.name).startsWith(wanted))
      || candidates[0];

    const gridsUrl = base + "grids/game/" + encodeURIComponent(match.id)
      + "?dimensions=600x900&types=static&limit=1";
    const gridsResponse = await fetch(gridsUrl, { headers });
    if (!gridsResponse.ok) return res.status(502).json({ error: "Could not retrieve the game cover." });

    const grids = await gridsResponse.json();
    const artwork = Array.isArray(grids.data) ? grids.data : [];
    if (!artwork.length || !artwork[0].url) return res.status(404).json({ error: "No portrait cover is available for this game." });

    return res.status(200).json({
      name: match.name,
      url: artwork[0].url,
      thumb: artwork[0].thumb || artwork[0].url
    });
  } catch (error) {
    return res.status(500).json({ error: "Poster lookup failed." });
  }
};
