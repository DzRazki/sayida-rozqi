-- نفّذي هذا الملف مرة واحدة في Supabase SQL Editor

create table if not exists recipe_stats (
  recipe_id uuid primary key references recipes(id) on delete cascade,
  views int not null default 0,
  likes int not null default 0,
  dislikes int not null default 0,
  updated_at timestamptz not null default now()
);

alter table recipe_stats enable row level security;

create policy "public read recipe stats"
  on recipe_stats for select
  using (true);

create policy "public insert recipe stats"
  on recipe_stats for insert
  with check (true);

create policy "public update recipe stats"
  on recipe_stats for update
  using (true)
  with check (true);

create or replace function increment_recipe_view(recipe_id uuid)
returns void
language sql
security definer
as $$
  insert into recipe_stats (recipe_id, views)
  values (recipe_id, 1)
  on conflict (recipe_id)
  do update set views = recipe_stats.views + 1, updated_at = now();
$$;

create or replace function react_to_recipe(recipe_id uuid, reaction text)
returns void
language plpgsql
security definer
as $$
begin
  insert into recipe_stats (recipe_id, likes, dislikes)
  values (recipe_id, case when reaction = 'like' then 1 else 0 end, case when reaction = 'dislike' then 1 else 0 end)
  on conflict (recipe_id)
  do update set
    likes = recipe_stats.likes + case when reaction = 'like' then 1 else 0 end,
    dislikes = recipe_stats.dislikes + case when reaction = 'dislike' then 1 else 0 end,
    updated_at = now();
end;
$$;

grant execute on function increment_recipe_view(uuid) to anon, authenticated;
grant execute on function react_to_recipe(uuid, text) to anon, authenticated;
