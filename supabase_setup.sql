-- ================================================================
-- SESTRD — Supabase: RLS + Realtime + Índices
-- Execute no SQL Editor do Supabase Dashboard:
--   https://supabase.com/dashboard/project/sjnjtaqlkfcrlcfzowmj/sql
--
-- IMPORTANTE: Execute os blocos NA ORDEM apresentada.
-- É seguro re-executar (usa IF NOT EXISTS / OR REPLACE).
-- ================================================================


-- ────────────────────────────────────────────────────────────────
-- BLOCO 1: Ativar RLS nas tabelas
-- ────────────────────────────────────────────────────────────────
-- Ativa Row Level Security. Sem políticas, NINGUÉM acessa.
-- As políticas abaixo concedem acesso ao anon (key pública do app).

ALTER TABLE rois     ENABLE ROW LEVEL SECURITY;
ALTER TABLE ros      ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;


-- ────────────────────────────────────────────────────────────────
-- BLOCO 2: Políticas para a tabela ROIS
-- ────────────────────────────────────────────────────────────────
-- O app usa a anon key para todas as operações.
-- Políticas permitem leitura/escrita para o papel anon.

DROP POLICY IF EXISTS "rois_select" ON rois;
DROP POLICY IF EXISTS "rois_insert" ON rois;
DROP POLICY IF EXISTS "rois_update" ON rois;
DROP POLICY IF EXISTS "rois_delete" ON rois;

CREATE POLICY "rois_select" ON rois
  FOR SELECT TO anon USING (true);

CREATE POLICY "rois_insert" ON rois
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "rois_update" ON rois
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "rois_delete" ON rois
  FOR DELETE TO anon USING (true);


-- ────────────────────────────────────────────────────────────────
-- BLOCO 3: Políticas para a tabela ROS
-- ────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "ros_select" ON ros;
DROP POLICY IF EXISTS "ros_insert" ON ros;
DROP POLICY IF EXISTS "ros_update" ON ros;
DROP POLICY IF EXISTS "ros_delete" ON ros;

CREATE POLICY "ros_select" ON ros
  FOR SELECT TO anon USING (true);

CREATE POLICY "ros_insert" ON ros
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "ros_update" ON ros
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "ros_delete" ON ros
  FOR DELETE TO anon USING (true);


-- ────────────────────────────────────────────────────────────────
-- BLOCO 4: Políticas para a tabela USUARIOS
-- ────────────────────────────────────────────────────────────────
-- SELECT: necessário para o login (busca por username + ativo)
-- INSERT: criação de novos usuários (chefia, verificado no app)
-- UPDATE: troca de senha, ativar/desativar
-- DELETE: exclusão permanente de usuário (chefia, verificado no app)

DROP POLICY IF EXISTS "usuarios_select" ON usuarios;
DROP POLICY IF EXISTS "usuarios_insert" ON usuarios;
DROP POLICY IF EXISTS "usuarios_update" ON usuarios;
DROP POLICY IF EXISTS "usuarios_delete" ON usuarios;

CREATE POLICY "usuarios_select" ON usuarios
  FOR SELECT TO anon USING (true);

CREATE POLICY "usuarios_insert" ON usuarios
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "usuarios_update" ON usuarios
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "usuarios_delete" ON usuarios
  FOR DELETE TO anon USING (true);


-- ────────────────────────────────────────────────────────────────
-- BLOCO 5: Realtime — publicações para rois e ros
-- ────────────────────────────────────────────────────────────────
-- Garante que mudanças nas tabelas disparam eventos Realtime
-- (necessário para a sincronização em tempo real entre usuários).

ALTER PUBLICATION supabase_realtime ADD TABLE rois;
ALTER PUBLICATION supabase_realtime ADD TABLE ros;

-- Verificar publicações ativas
SELECT tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;


-- ────────────────────────────────────────────────────────────────
-- BLOCO 6: Índices JSONB para performance
-- ────────────────────────────────────────────────────────────────
-- Acelera queries de busca por campo dentro do JSONB.

-- Índice GIN para buscas gerais no JSONB de rois
CREATE INDEX IF NOT EXISTS idx_rois_data_gin
  ON rois USING gin(data jsonb_path_ops);

-- Índice em updated_at para queries ordenadas por data
CREATE INDEX IF NOT EXISTS idx_rois_updated_at
  ON rois (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_ros_updated_at
  ON ros (updated_at DESC);

-- Índice no número da ROI (campo mais buscado)
CREATE INDEX IF NOT EXISTS idx_rois_numero_roi
  ON rois ((data->>'numero_roi'));

-- Índice no status (Pendente / Concluido)
CREATE INDEX IF NOT EXISTS idx_rois_status
  ON rois ((data->>'status'));

-- Índice na etapa do ARO
CREATE INDEX IF NOT EXISTS idx_rois_etapa
  ON rois ((data->'aro'->>'etapa'));


-- ────────────────────────────────────────────────────────────────
-- BLOCO 7: Verificação final
-- ────────────────────────────────────────────────────────────────

-- Verificar RLS ativo
SELECT tablename, rowsecurity AS rls_ativo
FROM pg_tables
WHERE tablename IN ('rois', 'ros', 'usuarios')
ORDER BY tablename;

-- Listar políticas criadas
SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE tablename IN ('rois', 'ros', 'usuarios')
ORDER BY tablename, policyname;

-- Listar índices criados
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE tablename IN ('rois', 'ros')
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
