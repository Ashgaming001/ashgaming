-- Add the Watch Dogs collection to ASH GAMING without duplicating existing entries.
INSERT INTO public.products (name, description, price, category, size, active, platform)
SELECT v.name, v.description, 200, 'Action', v.size, true, 'PS4'
FROM (VALUES
  ('Watch Dogs', 'Open-world action adventure about hacking and surveillance in Chicago.', '25 GB'),
  ('Watch Dogs 2', 'Open-world hacking adventure set in the San Francisco Bay Area.', '30 GB'),
  ('Watch Dogs: Legion', 'Open-world action adventure set in a near-future London.', '40 GB')
) AS v(name, description, size)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.products p
  WHERE lower(trim(p.name)) = lower(trim(v.name))
    AND coalesce(p.platform, 'PS4') = 'PS4'
);
