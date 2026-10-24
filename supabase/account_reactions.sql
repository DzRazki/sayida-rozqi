-- Run after fix_stats_rpc.sql. Keep legacy totals; do not rerun old scripts afterward.
begin;
create table public.account_recipe_reactions (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction text not null check (reaction in ('like', 'dislike')),
  primary key (recipe_id, user_id)
);
alter table public.account_recipe_reactions enable row level security;
revoke all on public.account_recipe_reactions from public, anon, authenticated;
grant select on public.account_recipe_reactions to authenticated;
create policy read_own_reaction on public.account_recipe_reactions for select to authenticated using (user_id = (select auth.uid()));
-- Counter writes are only allowed through controlled functions.
revoke insert, update, delete on public.recipe_stats from public, anon, authenticated;
drop policy if exists "public insert recipe stats" on public.recipe_stats;
drop policy if exists "public update recipe stats" on public.recipe_stats;
create or replace function public.set_recipe_reaction(p_recipe_id uuid, p_reaction text)
returns void language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_old text;
begin
  if v_user is null or not exists (select 1 from auth.users u where u.id = v_user and u.email is not null and u.email_confirmed_at is not null and not coalesce(u.is_anonymous, false)) then
    raise exception 'Sign in with a confirmed email account' using errcode = '42501';
  end if;
  if p_reaction is not null and p_reaction not in ('like', 'dislike') then
    raise exception 'Invalid reaction';
  end if;
  if not exists (select 1 from public.recipes r where r.id = p_recipe_id and r.published = true) then
    raise exception 'Recipe not available';
  end if;
  insert into public.recipe_stats (recipe_id) values (p_recipe_id) on conflict on constraint recipe_stats_pkey do nothing;
  perform 1 from public.recipe_stats s where s.recipe_id = p_recipe_id for update;
  select r.reaction into v_old from public.account_recipe_reactions r where r.recipe_id = p_recipe_id and r.user_id = v_user;
  if v_old is not distinct from p_reaction then return; end if;
  if p_reaction is null then
    delete from public.account_recipe_reactions r where r.recipe_id = p_recipe_id and r.user_id = v_user;
  else
    insert into public.account_recipe_reactions as existing (recipe_id, user_id, reaction) values (p_recipe_id, v_user, p_reaction)
    on conflict (recipe_id, user_id) do update set reaction = excluded.reaction;
  end if;
  update public.recipe_stats s set
    likes = s.likes + case when p_reaction = 'like' then 1 else 0 end - case when v_old = 'like' then 1 else 0 end,
    dislikes = s.dislikes + case when p_reaction = 'dislike' then 1 else 0 end - case when v_old = 'dislike' then 1 else 0 end,
    updated_at = now() where s.recipe_id = p_recipe_id;
end;
$$;
-- Secure the legacy endpoint too, including older app versions.
create or replace function public.react_to_recipe(recipe_id uuid, reaction text)
returns void language sql security invoker set search_path = public, pg_temp
as $$ select public.set_recipe_reaction($1, $2); $$;
revoke all on function public.set_recipe_reaction(uuid, text) from public, anon;
grant execute on function public.set_recipe_reaction(uuid, text) to authenticated;
revoke all on function public.react_to_recipe(uuid, text) from public, anon;
grant execute on function public.react_to_recipe(uuid, text) to authenticated;
commit;
