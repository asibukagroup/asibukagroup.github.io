export default {
    async fetch(request) {
      const url = new URL(request.url)
      const shouldInject = url.searchParams.get('function') === 'iframe'
  
      const response = await fetch(request)
      const contentType = response.headers.get("content-type") || ""
  
      if (!shouldInject || !contentType.includes("text/html")) {
        return response
      }
  
      return new HTMLRewriter()
        .on("body", new ScriptInjector())
        .transform(response)
    }
  }
  
  class ScriptInjector {
    element(element) {
      element.append(
        `<script>
          (() => {
            const q = new URLSearchParams(location.search);
            const t = q.get("title") || "Embedded";
            const s = q.get("short") || "";
            const o = q.get("orientation") || "landscape";
            const r = q.get("id");
            const d = document.getElementById("EmbedContent");
            const a = document.getElementById("EmbedTitle");
            document.title = t;
            a && (a.textContent = t);
            d && d.classList.add(o);
            if (s && r && d) {
              const i = document.createElement("iframe");
              i.src = \`https://\${s}/\${r}\`;
              i.title = t;
              i.style.border = "none";
              i.setAttribute("class", "media");
              i.setAttribute("allowfullscreen", "");
              i.setAttribute("frameborder", "0");
              i.setAttribute("allow", "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share");
              i.setAttribute("referrerpolicy", "strict-origin-when-cross-origin");
              d.removeAttribute('hidden');
              d.appendChild(i);
            }
            document.querySelectorAll(".hide-on-embed").forEach(el => el.remove());
            history.replaceState && history.replaceState({}, t, location.origin + location.pathname);
          })();
        </script>`,
        { html: true }
      );
    }
  }
  