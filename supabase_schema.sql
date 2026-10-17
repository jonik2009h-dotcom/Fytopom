-- =====================================================================
-- FYTOPOM: smazání a nové založení celé databáze (Supabase -> SQL Editor)
-- POZOR: smaže všechna data v těchto čtyřech tabulkách. Uživatelské účty zůstanou.
-- =====================================================================

drop table if exists public.komunitni_mapa cascade;
drop table if exists public.archiv_analyz cascade;
drop table if exists public.stromy_uzivatele cascade;
drop table if exists public.rate_limits cascade;

-- 1) Deník stromů (soukromé, každý vidí jen svoje)
create table public.stromy_uzivatele (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  nazev text,
  odruda text,
  lat double precision,
  lon double precision,
  poznamka text,
  datum_vysadby text,
  created_at timestamptz not null default now()
);
create index stromy_uzivatele_user_idx on public.stromy_uzivatele (user_id);
alter table public.stromy_uzivatele enable row level security;
create policy "stromy_own_rows" on public.stromy_uzivatele
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 2) Archiv analýz / PDF protokolů (soukromé)
create table public.archiv_analyz (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  typ_analyzy text not null,
  datum text,
  nazev_zaznamu text,
  zaznam_json text,
  created_at timestamptz not null default now()
);
create index archiv_analyz_user_typ_idx on public.archiv_analyz (user_id, typ_analyzy);
alter table public.archiv_analyz enable row level security;
create policy "archiv_own_rows" on public.archiv_analyz
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 3) Komunitní mapa (veřejně čitelná, zapisovat a mazat smí jen autor)
create table public.komunitni_mapa (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  typ text not null,
  nazev text not null,
  poznamka text,
  lat double precision not null,
  lon double precision not null,
  kontakt text,
  created_at timestamptz not null default now()
);
create index komunitni_mapa_created_idx on public.komunitni_mapa (created_at desc);
alter table public.komunitni_mapa enable row level security;
create policy "mapa_select_all" on public.komunitni_mapa
  for select to anon, authenticated using (true);
create policy "mapa_insert_own" on public.komunitni_mapa
  for insert to authenticated with check (auth.uid() = user_id);
create policy "mapa_delete_own" on public.komunitni_mapa
  for delete to authenticated using (auth.uid() = user_id);

-- 4) Omezovač počtu požadavků
create table public.rate_limits (
  id bigint generated always as identity primary key,
  key text not null,
  created_at timestamptz not null default now()
);
create index rate_limits_key_created_idx on public.rate_limits (key, created_at desc);
alter table public.rate_limits enable row level security;
create policy "rate_limits_insert" on public.rate_limits
  for insert to anon, authenticated with check (true);
create policy "rate_limits_select" on public.rate_limits
  for select to anon, authenticated using (true);

-- 5) Oprávnění
grant select on public.komunitni_mapa to anon;
grant select, insert, update, delete on public.stromy_uzivatele to authenticated;
grant select, insert, update, delete on public.archiv_analyz to authenticated;
grant select, insert, delete on public.komunitni_mapa to authenticated;
grant select, insert on public.rate_limits to anon, authenticated;

-- 6) Obnovení schématu v API
notify pgrst, 'reload schema';

-- Úklid rate_limits (obsahuje IP adresy), spouštěj občas ručně:
-- delete from public.rate_limits where created_at < now() - interval '1 day';
