-- Run once in Supabase SQL Editor. Does not delete local favorites.
begin;
create table public.account_recipe_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  primary key (user_id, recipe_id)
);
alter table public.account_recipe_favorites enable row level security;
revoke all on public.account_recipe_favorites from public, anon, authenticated;
grant select, insert, delete on public.account_recipe_favorites to authenticated;
create policy favorites_read_own on public.account_recipe_favorites for select to authenticated using (user_id = (select auth.uid()));
create policy favorites_insert_own on public.account_recipe_favorites for insert to authenticated with check (user_id = (select auth.uid()) and exists (select 1 from public.recipes r where r.id = recipe_id and r.published = true));
create policy favorites_delete_own on public.account_recipe_favorites for delete to authenticated using (user_id = (select auth.uid()));
commit;
