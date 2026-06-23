-- ============================================================
-- Item 5 — Upload de notificação (Supabase Storage)
-- Execute este script no SQL Editor do Supabase UMA vez.
-- Cria o bucket "notificacoes" e as políticas de acesso para
-- a chave anon usada pelo aplicativo.
-- ============================================================

-- 1. Cria o bucket (público para leitura via getPublicUrl)
insert into storage.buckets (id, name, public)
values ('notificacoes', 'notificacoes', true)
on conflict (id) do nothing;

-- 2. Políticas de acesso (o app usa a chave anon)
--    Remova-as antes de recriar, caso já existam.
drop policy if exists "notif anon upload" on storage.objects;
drop policy if exists "notif anon read"   on storage.objects;
drop policy if exists "notif anon delete" on storage.objects;

create policy "notif anon upload"
  on storage.objects for insert to anon
  with check (bucket_id = 'notificacoes');

create policy "notif anon read"
  on storage.objects for select to anon
  using (bucket_id = 'notificacoes');

create policy "notif anon delete"
  on storage.objects for delete to anon
  using (bucket_id = 'notificacoes');

-- Observações:
--  - Bucket público: qualquer pessoa com a URL do PDF consegue abri-lo.
--    Para uso interno do SEST-RD isso costuma ser aceitável; se precisar
--    restringir, troque para bucket privado (public = false) e gere URLs
--    assinadas (createSignedUrl) no código.
--  - Limite de 10 MB por arquivo é validado no front-end (uploadNotificacao).
