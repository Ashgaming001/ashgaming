-- ASH GAMING: seed popular PS4 and PS5 titles with cover artwork.
-- Run once in Supabase SQL Editor for project xqdiumkisbtkjcgfuyzc.
-- Prices start at the store's sample price of ₹200; change them in the admin dashboard.
insert into public.products
  (name, description, price, category, size, image_url, active, platform)
select v.name, v.description, 200, v.category, v.size, v.image_url, true, v.platform
from (values
  ('Red Dead Redemption 2','Open-world western action-adventure following Arthur Morgan.','Story','100 GB','https://upload.wikimedia.org/wikipedia/en/4/44/Red_Dead_Redemption_II.jpg','PS4'),
  ('God of War','Kratos and Atreus journey through the Norse realms.','Action','45 GB','https://upload.wikimedia.org/wikipedia/en/a/a7/God_of_War_4_cover.jpg','PS4'),
  ('The Last of Us Part II','A cinematic post-apocalyptic action-adventure story.','Story','100 GB','https://upload.wikimedia.org/wikipedia/en/4/4f/The_Last_of_Us_Part_II_cover_art.jpg','PS4'),
  ('Grand Theft Auto V','Open-world action across Los Santos.','Action','90 GB','https://upload.wikimedia.org/wikipedia/en/a/a5/Grand_Theft_Auto_V.png','PS4'),
  ('Ghost of Tsushima','Open-world samurai adventure set in feudal Japan.','Action','50 GB','https://upload.wikimedia.org/wikipedia/en/b/b6/Ghost_of_Tsushima.jpg','PS4'),
  ('Uncharted 4','Nathan Drake returns for one last globe-trotting adventure.','Adventure','50 GB','https://upload.wikimedia.org/wikipedia/en/1/1a/Uncharted_4_box_artwork.jpg','PS4'),
  ('EA Sports FC 27','Football simulation featuring clubs and national teams.','Sports','50 GB','https://res.plaisio.gr/c_limit%2Cf_auto%2Cw_2048%2Cq_75/d_Shared%3ANotFound%3Aproduct-notfound.jpg/Shared/Product/Images/5312825.jpg','PS4'),
  ('Days Gone','Survive a dangerous open world on your motorcycle.','Action','45 GB','https://www.static-src.com/wcsstore/Indraprastha/images/catalog/full/MTA-2967522/sony_sony-ps4-days-gone-standard-dvd-game--pre-order-_full10.jpg','PS4'),
  ('EA Sports FC 27','Football simulation featuring clubs and national teams.','Sports','55 GB','https://res.plaisio.gr/c_limit%2Cf_auto%2Cw_2048%2Cq_75/d_Shared%3ANotFound%3Aproduct-notfound.jpg/Shared/Product/Images/5312825.jpg','PS5'),
  ('NBA 2K27','Basketball simulation featuring MyCAREER and MyTEAM.','Sports','100 GB','https://static01.galaxus.com/productimages/3/0/2/7/4/6/7/0/0/9/5/9/8/1/8/6/4/0/9/01a0a034-8a1f-7784-9ff9-c0d1b04f9c4d_sea.jpeg','PS5'),
  ('Ghost of Yōtei','Samurai action-adventure following Atsu in 1600s Japan.','Action','80 GB','https://cdn.hstatic.net/products/1000154920/ghost_of_y_tei_ps5_ec9958f7286b43f59004c69ba7e665d0_grande.png','PS5'),
  ('Marvel’s Spider-Man 2','Play as Peter Parker and Miles Morales in an expanded New York.','Action','90 GB','https://www.pcrichard.com/dw/image/v2/BFXM_PRD/on/demandware.static/-/Sites-pcrichard-master-product-catalog/default/dw4b0aa084/images/hires/Z_711719567653.jpg?sh=800&sm=fit&sw=800','PS5'),
  ('Black Myth: Wukong','Action RPG inspired by the classic Journey to the West.','Action','80 GB','https://media.falabella.com/falabellaCO/147428944_01/w%3D1500%2Ch%3D1500%2Cfit%3Dcover','PS5'),
  ('The Blood of Dawnwalker','Dark fantasy action RPG with human and vampire abilities.','Action','70 GB','https://www.thegamecollection.net/cdn/shop/files/PS5_PACKSHOT_2D_PEGI.png?v=1779805611&width=1214','PS5'),
  ('Resident Evil 4','Survival horror remake starring Leon S. Kennedy.','Horror','60 GB','https://i5.walmartimages.com/seo/Resident-Evil-4-PS5-Playstation-5_28a978d3-7c13-4bb8-a575-c184e3faa507.350e7cc0883f7dce67dc53bfbdc76561.jpeg','PS5'),
  ('Forza Horizon 5','Open-world racing across the landscapes of Mexico.','Racing','110 GB','https://cdn.awsli.com.br/800x800/2549/2549404/produto/340548819/forza-horizon-5-para-ps5-liongames-fgn4rwa1o2.webp','PS5')
) as v(name, description, category, size, image_url, platform)
where not exists (
  select 1 from public.products p
  where lower(p.name) = lower(v.name)
    and coalesce(p.platform,'') = v.platform
);
