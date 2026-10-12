# Relatório

Relatório do Marco 1 no [modelo de Capítulo de Livro da SBC](https://www.sbc.org.br/wp-content/uploads/2024/07/modeloparapublicaodecaptulosdelivros.zip) (Regra 4).

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

As figuras do MER conceitual e do modelo lógico estão em `marco1/raw/figuras/`, em PDF vetorial, e podem ser ampliadas sem perder nitidez. Cada recorte tem o número da figura no relatório:

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
| `figura-1-10-logico-geral.pdf` | 1.10 · Modelo lógico, visão geral |
| `figura-1-11-logico-parte-a.pdf` | 1.11 · Lógico, parte A: Pessoa, Período de Associação, Assina, Auditoria e Organiza |
| `figura-1-12-logico-parte-b.pdf` | 1.12 · Lógico, parte B: Vínculo Institucional, Instituição, Benefício e Documento de Comprovação |
| `figura-1-13-logico-parte-c.pdf` | 1.13 · Lógico, parte C: Evento e Edição |
| `figura-1-14-logico-parte-d.pdf` | 1.14 · Lógico, parte D: Faixa de Inscrição, Preço, Categoria de Inscrição e Restringe |
| `figura-1-15-logico-parte-e.pdf` | 1.15 · Lógico, parte E: Certificado e Atividade |
| `figura-1-16-logico-parte-f.pdf` | 1.16 · Lógico, parte F: Inscrição, Trabalho Científico, Pagamento, Termo e Responde |
| `figura-1-17-logico-parte-g.pdf` | 1.17 · Lógico, parte G: Inscrição em Atividade e Item Financeiro |

A Figura 1.1 (legenda de cores e formas) é desenhada no próprio LaTeX. Os recortes saem das exportações completas do brModelo, que ficam na mesma pasta (`mer-final.pdf`, `mer-v1.pdf` e `logico-final.pdf`). As medidas de cada recorte estão comentadas em `preambulo.tex`.

## Manter atualizado

A pasta `marco1/raw/` deve ser atualizada sempre que o relatório mudar. Qualquer alteração no texto, nas figuras, no MER ou no modelo lógico precisa ser feita nela, seguida da recompilação e da troca de `final/relatorio-marco1.pdf`, para que fonte e PDF continuem iguais. Se o MER ou o modelo lógico for exportado de novo, substitua `figuras/mer-final.pdf` ou `figuras/logico-final.pdf` e gere de novo os recortes `figura-1-*`, porque os elementos do diagrama mudam de posição. Se uma figura nova mudar a numeração, renomeie os arquivos e atualize a tabela acima.
