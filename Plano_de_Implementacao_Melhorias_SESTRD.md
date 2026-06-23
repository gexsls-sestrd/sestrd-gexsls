# Plano de Implementação — Melhorias na aplicação Plan, Sync & Control (SEST‑RD)

Base: `index.html` (arquivo único, ~321 KB). Arquitetura JSONB‑only, IDs numéricos, dias úteis via `addWD(date, days)` (linha 518), persistência por `save()` / `saveSingle()`, deploy via API (`deploy.ps1`).

Ordem sugerida de execução: **3 → 4 → 6 → 7 → 8 → 1 → 2 → 5** (dos ajustes triviais aos que exigem decisão de design / armazenamento).

---

## 1. Acentuação correta em notificações e despachos SEI

**Causa real (confirmada no código):** os templates são escritos *sem acento de propósito* (ex.: linhas 3114‑3122 "atencao", "razao", "conclusao"; linhas 3382‑3404). Isso porque o PDF é gerado com `jsPDF` usando a fonte padrão **Helvetica/WinAnsi** (`doc.setFont`, `doc.text` em 3144‑3156), que corrompe caracteres acentuados UTF‑8.

**Solução:**
1. Embutir uma fonte Unicode TTF no jsPDF (ex.: Roboto/DejaVu) via `doc.addFileToVFS(...)` + `doc.addFont(...)` + `doc.setFont('Roboto')`. A fonte pode ir embutida como base64 dentro do próprio `index.html` (coerente com o padrão single‑file) ou carregada de CDN no boot.
2. Reescrever os textos dos templates **com acentuação correta** (funções que montam `notif-text`, ~3110‑3125, e o despacho SEI, ~3380‑3404).
3. Validar a quebra de linha: `doc.splitTextToSize(texto, 165)` (linha 3149) já funciona com Unicode após trocar a fonte.

**Esforço:** baixo‑médio. **Risco:** baixo. **Impacto:** alto (documento oficial).
**Teste:** gerar PDF de notificação e de despacho e conferir "ã, ç, é, ô" renderizados.

---

## 2. Editar comentários sem duplicar texto no log

**Estado atual:** comentários são `push` num array `{ts, user, texto}` e são imutáveis. Pontos de criação/render:
- ROs: `salvarComentario` (3016) e render do modal (1973‑2006).
- ROIs: `comentarios_roi` em 3675‑3726.

**Solução (espelhar o comportamento do PAT):**
1. Acrescentar ao objeto do comentário os campos `editado_em` e `historico:[]` (sem alterar a estrutura JSONB existente — apenas chaves novas).
2. No render de cada comentário (1983‑1988 e equivalente ROI), adicionar um botão **✏ Editar** (lápis no canto superior direito).
3. Ao salvar a edição: substituir `texto` *in place*, gravar `{texto_anterior, ts}` em `historico` e marcar `editado_em`. **Não** dar novo `push` — assim o texto antigo não se duplica na visualização; fica só num histórico de ações recolhível.
4. Exibir selo discreto "(editado)" com tooltip mostrando o histórico.

**Esforço:** médio. **Risco:** médio (mexe em render + persistência). **Impacto:** médio.

---

## 3. Prazo de 5 → 10 dias úteis (Data Limite ARO)

**Estado atual:** o limite da ARO é calculado como `addWD(dataNotificacao, 5)` em **vários pontos** — todos precisam mudar para `10`:
- `handleChange` / `edit-notif`: linha **3212**
- linha **3521** (`novoLim`)
- linha **3795** (`limARO`)
- linha **3951** (`limARO`)
- linha **4005** (`f-data-limite`)

**Solução recomendada:** criar uma constante única (ex.: `var PRAZO_ARO_DU = 10;`) e substituir os literais `5` dessas chamadas por ela, evitando divergência futura. Atualizar o rótulo "DATA LIMITE ARO (+5 D.U.)" → "(+10 D.U.)".

> ⚠️ **Confirmar antes:** a instrução original do projeto fixava 5 dias úteis para a notificação. Validar se a mudança vale para **todo** o fluxo da ARO ou apenas para um trecho específico. O `addWD` de 3 dias da baixa (3226/3351) e o de 10 dias do SEI (3317) **não** mudam.

**Esforço:** baixo. **Risco:** baixo.

---

## 4. Campos de manifestação no card Processo SEI

**Local:** card "Processo SEI — Resistência Injustificada", render em **1399‑1413** (`form-grid`).

**Solução:** adicionar três campos `type="date"` ligados a chaves novas no objeto `roi.sei` (JSONB):
- `roi.sei.manif_sgca` → "Manifestação SGCA em:"
- `roi.sei.manif_sard` → "Manifestação SARD em:"
- `roi.sei.manif_chefia` → "Manifestação chefia imediata em:"

Reaproveitar o padrão `data-action`/`data-id` + tratamento em `handleChange` (3193+) para persistir via `save()`.

**Esforço:** baixo. **Risco:** baixo.

---

## 5. Upload da notificação enviada ao servidor

**Local:** barra de ações do Detalhe ROI/ARO (botões em ~1316‑1320).

**Decisão de armazenamento (definir antes de implementar):**
- **Opção A — base64 no JSONB:** rápido de implementar, sem dependência externa, mas incha o banco e o payload de `save()`. Aceitável só para PDFs pequenos.
- **Opção B — Supabase Storage (recomendado):** botão de upload envia o arquivo ao bucket e grava apenas a URL/markup em `roi.anexos[]`. Mantém o JSONB enxuto. Exige configurar bucket + políticas (`supabase_setup.sql`).

**Solução:** botão "📎 Anexar notificação" → `<input type="file" accept="application/pdf">` → conforme a opção, grava em `roi.anexos` (`{nome, data, url|base64, enviado_por}`) e renderiza a lista com link de download.

**Esforço:** médio (A) / médio‑alto (B). **Risco:** médio. **Impacto:** médio.

---

## 6. Campo para número da RO quando etapa = "Processo em Fase de RO"

**Estado atual:** o modelo de RO já tem `numero_ro` (linhas 426‑440, 1784, 1837), mas no card da ARO, quando a etapa é "Processo em Fase de RO", não há campo para inserir esse número. Dropdown de etapas em 1372.

**Solução:** render condicional — quando `roi.aro.etapa === 'Processo em Fase de RO'`, exibir input "Número da RO" ligado a `roi.aro.numero_ro` (chave nova no JSONB), com máscara do padrão `9836.000000/2025-00`. Persistir via `handleChange`.

**Esforço:** baixo. **Risco:** baixo.

---

## 7. Tornar editável a "Data Limite SEI (+10 dias úteis)"

**Estado atual:** campo `readonly`, calculado por `addWD(dataAbertura, 10)` (render em **1404‑1405**; cálculo em **3317**).

**Solução:**
1. Remover `readonly` e adicionar `data-action="sei-limite-manual"` + `data-id`.
2. Em `handleChange`, gravar `roi.sei.data_limite` com o valor manual e marcar `roi.sei.limite_manual = true`.
3. No recálculo automático (3317), **só** recalcular se `limite_manual` não estiver setado — assim a edição manual não é sobrescrita.
4. O semáforo de cores (`getColor`/badge SEI em 1397) passa a seguir a data manual automaticamente.

**Esforço:** baixo. **Risco:** baixo‑médio (interação com o semáforo).

---

## 8. Tornar editável a "Data Limite (+35 dias corridos)" da exigência

**Estado atual:** campo `readonly`, 35 dias corridos sobre a data de envio da exigência (render em **1440‑1441**; lógica em 3237/3270). O texto informativo (1434) diz que o semáforo segue essa data.

**Solução:** mesma abordagem do item 7 — remover `readonly`, `data-action="exig-limite-manual"`, flag `roi.aro.exigencia_limite_manual`, e condicionar o recálculo automático (3237/3270) à ausência da flag. `getExigenciaColor`/`getExigenciaStr` (1417‑1420) seguem a data ajustada.

**Esforço:** baixo. **Risco:** baixo‑médio.

---

## Resumo de esforço

| # | Item | Esforço | Risco | Decisão pendente |
|---|------|---------|-------|------------------|
| 1 | Acentuação PDF | Médio | Baixo | — |
| 2 | Editar comentários | Médio | Médio | Formato do histórico |
| 3 | 5 → 10 dias úteis | Baixo | Baixo | **Escopo do prazo** |
| 4 | Campos manifestação SEI | Baixo | Baixo | — |
| 5 | Upload de notificação | Médio/Alto | Médio | **Armazenamento (A ou B)** |
| 6 | Nº da RO em fase de RO | Baixo | Baixo | — |
| 7 | Data Limite SEI editável | Baixo | Baixo‑Médio | Manual sobrepõe auto? |
| 8 | Data Limite exigência editável | Baixo | Baixo‑Médio | Idem item 7 |

## Pontos a decidir antes de codificar
1. **Item 3:** a troca 5→10 vale para todo o fluxo da ARO ou só para parte dele?
2. **Item 5:** anexos em base64 no JSONB (simples) ou Supabase Storage (recomendado)?
3. **Itens 7 e 8:** a data inserida manualmente deve sobrepor o cálculo automático permanentemente (flag) — confirmar comportamento desejado do semáforo.
