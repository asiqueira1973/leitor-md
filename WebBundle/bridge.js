// bridge.js — orquestração do renderizador (spec 8.5).
//
// Configura o markdown-it (GFM: tabelas, tachado, task-lists, notas de rodapé),
// o realce de código (highlight.js), a matemática (KaTeX via texmath) e os
// diagramas (Mermaid). Expõe à camada Swift (RenderizadorWebView):
//   window.renderMarkdown(texto)      — renderiza o documento
//   window.aplicarPreferencias(prefs) — tema/fonte/tamanho ao vivo (spec 7.3)
//   window.obterTOC()                 — sumário (headings) em JSON (spec 8.5)
//   window.irPara(id)                 — rola até uma seção do TOC

(function () {
  "use strict";

  // --- markdown-it: parser GFM (spec 8.5) --------------------------------
  const md = window.markdownit({
    html: false,        // não renderiza HTML cru (segurança ao abrir arquivos de terceiros)
    linkify: true,
    typographer: false, // fidelidade ao original (spec 0.3)
    highlight: realçarCodigo
  });

  // Não linkar texto solto tipo "arquivo.md" como se fosse domínio — só URLs
  // explícitas (http/https). Mais fiel ao original (spec 0.3).
  md.linkify.set({ fuzzyLink: false, fuzzyEmail: false });

  md.use(window.markdownitTaskLists, { label: true, labelAfter: true });
  md.use(window.markdownitFootnote);
  md.use(window.texmath, {
    engine: window.katex,
    delimiters: "dollars",   // $...$ inline e $$...$$ em bloco
    katexOptions: { throwOnError: false }
  });

  // Realce de código; blocos ```mermaid viram <pre class="mermaid"> para o Mermaid.
  function realçarCodigo(str, lang) {
    if (lang === "mermaid") {
      return '<pre class="mermaid">' + md.utils.escapeHtml(str) + "</pre>";
    }
    if (lang && window.hljs.getLanguage(lang)) {
      try {
        const html = window.hljs.highlight(str, { language: lang }).value;
        return '<pre class="hljs"><code>' + html + "</code></pre>";
      } catch (e) { /* cai no escape abaixo */ }
    }
    return '<pre class="hljs"><code>' + md.utils.escapeHtml(str) + "</code></pre>";
  }

  window.mermaid.initialize({ startOnLoad: false, securityLevel: "strict", theme: "default" });

  // --- Renderização (spec 8.5) -------------------------------------------
  window.renderMarkdown = function (markdown) {
    const alvo = document.getElementById("conteudo");
    alvo.innerHTML = md.render(markdown || "");
    atribuirIdsAosHeadings(alvo);
    renderizarMermaid(alvo);
  };

  // Renderiza e AGUARDA o Mermaid terminar, devolvendo o HTML do conteúdo — usado
  // pela exportação (spec 8.7), que precisa do resultado final (incl. diagramas).
  window.renderParaExportacao = async function (markdown) {
    const alvo = document.getElementById("conteudo");
    alvo.innerHTML = md.render(markdown || "");
    atribuirIdsAosHeadings(alvo);
    const nos = alvo.querySelectorAll("pre.mermaid");
    if (nos.length) {
      try { await window.mermaid.run({ nodes: nos }); } catch (e) { /* ignora diagrama inválido */ }
    }
    return alvo.innerHTML;
  };

  // Renderiza os diagramas Mermaid presentes (spec 8.5). Só age se houver blocos,
  // para não pagar o custo do Mermaid em documentos sem diagrama (spec 22).
  function renderizarMermaid(container) {
    const nos = container.querySelectorAll("pre.mermaid");
    if (nos.length === 0) return;
    try {
      window.mermaid.run({ nodes: nos });
    } catch (e) { /* diagrama inválido não deve derrubar a leitura */ }
  }

  // Atribui um id único a cada heading, para o TOC navegar (spec 8.5).
  function atribuirIdsAosHeadings(container) {
    const headings = container.querySelectorAll("h1, h2, h3, h4, h5, h6");
    headings.forEach(function (h, i) {
      if (!h.id) h.id = "sec-" + i + "-" + slug(h.textContent);
    });
  }

  function slug(texto) {
    return (texto || "").toLowerCase()
      .normalize("NFD").replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  }

  // --- Sumário / TOC (spec 8.5) ------------------------------------------
  window.obterTOC = function () {
    const headings = document.querySelectorAll("#conteudo h1, #conteudo h2, #conteudo h3, #conteudo h4, #conteudo h5, #conteudo h6");
    const itens = [];
    headings.forEach(function (h) {
      itens.push({ nivel: parseInt(h.tagName.substring(1), 10), texto: h.textContent, id: h.id });
    });
    return JSON.stringify(itens);
  };

  window.irPara = function (id) {
    const el = document.getElementById(id);
    if (el) el.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  // --- Preferências: tema / fonte / tamanho ao vivo (spec 7.3 / 8.5) -----
  window.aplicarPreferencias = function (prefs) {
    if (!prefs) return;
    const raiz = document.documentElement;
    const escuro = prefs.tema === "escuro" ||
      (prefs.tema === "sistema" && window.matchMedia("(prefers-color-scheme: dark)").matches);

    raiz.setAttribute("data-tema", escuro ? "escuro" : "claro");
    if (prefs.fonteLeitura) raiz.setAttribute("data-fonte", prefs.fonteLeitura);
    if (prefs.tamanhoFonte) raiz.style.setProperty("--tamanho-fonte", prefs.tamanhoFonte + "px");

    aplicarTemaCodigo(prefs.temaSintaxe || "github", escuro);
    window.mermaid.initialize({ startOnLoad: false, securityLevel: "strict",
                               theme: escuro ? "dark" : "default" });
  };

  // Troca o CSS de realce de código conforme a preferência e o modo claro/escuro.
  function aplicarTemaCodigo(tema, escuro) {
    const mapa = {
      github: escuro ? "github-dark" : "github",
      solarized: escuro ? "solarized-dark" : "solarized-light",
      dracula: "dracula",
      monokai: "monokai"
    };
    const arquivo = mapa[tema] || (escuro ? "github-dark" : "github");
    document.getElementById("tema-codigo").href = "vendor/hljs-themes/" + arquivo + ".min.css";
  }
})();
