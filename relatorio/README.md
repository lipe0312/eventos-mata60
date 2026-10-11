# Relatório

Relatório do Marco 1 no modelo de Capítulo de Livro da SBC (Regra 4).

| Caminho | Conteúdo |
|---------|----------|
| `marco1/final/relatorio-marco1.pdf` | Versão atual do relatório, com o link deste repositório |
| `marco1/raw/` | Fonte LaTeX que gera o PDF: `main.tex`, `preambulo.tex`, a classe `SBCbookchapter.cls`, as seções em `secoes/` e as figuras em `figuras/` |

## Compilar

Pelo Overleaf: compacte a pasta `marco1/raw/` em `.zip`, use *New Project > Upload Project* e compile com pdfLaTeX. O resultado é igual ao PDF de `final/`.

Na máquina, com TeX Live ou MiKTeX:

```bash
cd relatorio/marco1/raw
latexmk -pdf main.tex
```

## Figuras

As figuras do MER estão em `marco1/raw/figuras/`, em PDF vetorial, e podem ser ampliadas sem perder nitidez. Cada recorte tem o número da figura no relatório:

| Arquivo | Figura no PDF |
|---------|---------------|
| `figura-1-2-mer-v1.pdf` | 1.2 · Primeira versão do modelo conceitual |
| `figura-1-3-mer-geral.pdf` | 1.3 · Modelo conceitual final, visão geral |
| `figura-1-4-mer-parte-a.pdf` | 1.4 · Parte A: evento, edição e organização |
| `figura-1-5-mer-parte-b.pdf` | 1.5 · Parte B: categorias, faixas, preços e atividades |
| `figura-1-6-mer-parte-c.pdf` | 1.6 · Parte C: pessoas, associação, instituições e benefícios |
| `figura-1-7-mer-parte-d.pdf` | 1.7 · Parte D: inscrição, itens, pagamentos, documentos e atividades selecionadas |
| `figura-1-8-mer-parte-e.pdf` | 1.8 · Parte E: trabalhos científicos e termos |
| `figura-1-9-mer-parte-f.pdf` | 1.9 · Parte F: certificados e auditoria |

A Figura 1.1 (legenda de cores e formas) é desenhada no próprio LaTeX. Os recortes saem das exportações completas do brModelo, que ficam na mesma pasta (`mer-final.pdf`, versão final, e `mer-v1.pdf`); as medidas de cada recorte estão comentadas em `preambulo.tex`.

## Manter atualizado

A pasta `marco1/raw/` deve ser atualizada sempre que o relatório mudar. Qualquer alteração no texto, nas figuras ou no MER precisa ser feita nela, seguida da recompilação e da troca de `final/relatorio-marco1.pdf`, para que fonte e PDF continuem iguais. Se o MER for exportado de novo, substitua `figuras/mer-final.pdf` e gere de novo os recortes `figura-1-*`, porque os elementos do diagrama mudam de posição. Se uma figura nova mudar a numeração, renomeie os arquivos e atualize a tabela acima.

## Pendente: modelo lógico

O modelo lógico ainda não está pronto e aparece marcado como pendente na seção de Modelagem. Ele deve ser:

1. completado e corrigido no brModelo: 24 tabelas (20 entidades e as junções Assina, Responde, Organiza e Restringe), tipos iguais aos da DDL e Recebe como chave estrangeira em Benefício, e não como tabela;
2. exportado em PDF para `modelagem/logico/` e copiado para `marco1/raw/figuras/`;
3. inserido na subseção "Modelo lógico" de `marco1/raw/secoes/02-modelagem.tex`, com visão geral e recortes por parte, no mesmo padrão do MER conceitual;
4. recompilado, substituindo `final/relatorio-marco1.pdf`.
