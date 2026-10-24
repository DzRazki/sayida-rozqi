-- Run after schema_phase2.sql in Supabase SQL Editor.
-- Preserves existing counters; does not implement unique reactions.

create or replace function public.increment_recipe_view(recipe_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  insert into public.recipe_stats (recipe_id, views)
  values ($1, 1)
  on conflict on constraint recipe_stats_pkey
  do update set views = recipe_stats.views + 1, updated_at = now();
$$;

create or replace function public.react_to_recipe(recipe_id uuid, reaction text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if $2 is null or $2 not in ('like', 'dislike') then
    raise exception 'Invalid reaction';
  end if;
  insert into public.recipe_stats (recipe_id, likes, dislikes)
  values ($1, case when $2 = 'like' then 1 else 0 end, case when $2 = 'dislike' then 1 else 0 end)
  on conflict on constraint recipe_stats_pkey
  do update set
    likes = recipe_stats.likes + case when $2 = 'like' then 1 else 0 end,
    dislikes = recipe_stats.dislikes + case when $2 = 'dislike' then 1 else 0 end,
    updated_at = now();
end;
$$;

grant execute on function public.increment_recipe_view(uuid) to anon, authenticated;
grant execute on function public.react_to_recipe(uuid, text) to anon, authenticated;
