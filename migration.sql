-- =============================================================
-- SESTRD — Nota sobre Schema do Banco de Dados
-- =============================================================
--
-- ⚠️  NENHUMA MIGRAÇÃO SQL É NECESSÁRIA.
--
-- As tabelas 'rois' e 'ros' armazenam TODOS os campos dentro
-- de uma única coluna JSONB chamada 'data':
--
--   rois  →  { id, data (jsonb), updated_at }
--   ros   →  { id, data (jsonb), updated_at }
--
-- Os novos campos adicionados pela atualização:
--
--   ✅  data_srid_coben        (data de encaminhamento SRID/COBEN)
--   ✅  data_abertura_suporte  (data de abertura do suporte técnico)
--
-- ...são gravados AUTOMATICAMENTE dentro do objeto JSONB
-- quando o usuário preenche os campos e o sistema chama
-- saveSingle(roi) → upsert({ id, data: roi }).
--
-- NÃO execute ALTER TABLE — não há colunas a adicionar.
--
-- =============================================================
-- Verificação opcional (SQL Editor do Supabase):
-- =============================================================

-- Ver estrutura das tabelas
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('rois', 'ros', 'usuarios')
ORDER BY table_name, ordinal_position;

-- Conferir campos dentro do JSONB
SELECT
  id,
  data->>'numero_roi'       AS numero_roi,
  data->>'status'           AS status,
  data->>'data_srid_coben'  AS enc_srid_coben,
  data->'aro'->>'etapa'     AS etapa
FROM rois
ORDER BY updated_at DESC
LIMIT 10;
