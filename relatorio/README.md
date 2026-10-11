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

As figuras do MER são PDFs vetoriais exportados do brModelo. Os recortes de cada parte do diagrama estão em `preambulo.tex` (`\merA` a `\merF`), em pontos, sobre `figuras/mer-final.pdf`.

## Manter atualizado

A pasta `marco1/raw/` deve ser atualizada sempre que o relatório mudar. Qualquer alteração no texto, nas figuras ou no MER precisa ser feita nela, seguida da recompilação e da troca de `final/relatorio-marco1.pdf`, para que fonte e PDF continuem iguais. Se o MER for exportado de novo, substitua `figuras/mer-final.pdf` e confira os recortes em `preambulo.tex`, porque os elementos do diagrama mudam de posição.

## Pendente: modelo lógico

O modelo lógico ainda não está pronto e aparece marcado como pendente na seção de Modelagem. Ele deve ser:

1. completado e corrigido no brModelo: 24 tabelas (20 entidades e as junções Assina, Responde, Organiza e Restringe), tipos iguais aos da DDL e Recebe como chave estrangeira em Benefício, e não como tabela;
2. exportado em PDF para `modelagem/logico/` e copiado para `marco1/raw/figuras/`;
3. inserido na subseção "Modelo lógico" de `marco1/raw/secoes/02-modelagem.tex`, com visão geral e recortes por parte, no mesmo padrão do MER conceitual;
4. recompilado, substituindo `final/relatorio-marco1.pdf`.
