export default {
  async fetch(request) {
    const url = new URL(request.url)
    const func = url.searchParams.get('function')

    const response = await fetch(request)
    const contentType = response.headers.get("content-type") || ""

    if (!contentType.includes("text/html")) {
      return response
    }

    let injector
    if (func === 'iframe') {
      injector = new IframeScriptInjector()
    } else if (func === 'komisi-asibuka-logistics') {
      injector = new KomisiScriptInjector()
    }

    if (injector) {
      return new HTMLRewriter()
        .on("body", injector)
        .transform(response)
    }

    return response
  }
}

class IframeScriptInjector {
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
    )
  }
}

class KomisiScriptInjector {
  element(element) {
    element.append(
      `<script>
        (function() {
          const params = new URLSearchParams(window.location.search);
          const id1 = params.get('id1');
          const gid1 = params.get('gid1');
          const id2 = params.get('id2');
          const gid2 = params.get('gid2');
          const title = params.get('title');
          const embedDetails = document.getElementById('EmbedDetails');
          const embedResult = document.getElementById('EmbedResult');
          const embedTitle = document.getElementById('EmbedTitle');

          if (title) {
            document.title = title;
            if (embedTitle) {
              embedTitle.textContent = '';
              embedTitle.append(title);
            }
          }

          if (id1 && gid1 && embedDetails) {
            const csvDetails = \`https://docs.google.com/spreadsheets/d/e/\${id1}/pub?gid=\${gid1}&single=true&output=csv\`;
            fetch(csvDetails)
              .then(res => res.text())
              .then(csv => {
                const rows = csv.trim().split('\\n').map(r => r.split(','));
                const table = document.createElement('table');
                rows.forEach((row, i) => {
                  const tr = document.createElement('tr');
                  row.forEach(cell => {
                    const el = document.createElement(i === 0 ? 'th' : 'td');
                    el.innerHTML = cell; // Render HTML
                    tr.appendChild(el);
                  });
                  table.appendChild(tr);
                });
                embedDetails.innerHTML = '';
                embedDetails.removeAttribute('hidden');
                embedDetails.appendChild(table);
              })
              .catch(err => {
                embedDetails.textContent = 'Failed to load data.';
                console.error('CSV fetch error:', err);
              });
          }

          if (id2 && gid2 && embedResult) {
            const csvResult = \`https://docs.google.com/spreadsheets/d/e/\${id2}/pub?gid=\${gid2}&single=true&output=csv\`;
            fetch(csvResult)
              .then(res => res.text())
              .then(csv => {
                const rows = csv.trim().split('\\n').map(r => r.split(','));
                const table = document.createElement('table');
                rows.forEach((row, i) => {
                  const tr = document.createElement('tr');
                  row.forEach(cell => {
                    const el = document.createElement(i === 0 ? 'th' : 'td');
                    el.innerHTML = cell; // Render HTML
                    tr.appendChild(el);
                  });
                  table.appendChild(tr);
                });
                embedResult.innerHTML = '';
                embedResult.removeAttribute('hidden');

                const heading = document.createElement('h2');
                heading.className = 'main-heading';
                heading.textContent = 'Detil Transaksi';
                embedResult.parentNode.insertBefore(heading, embedResult);
                embedResult.appendChild(table);
              })
              .catch(err => {
                embedResult.textContent = 'Failed to load data.';
                embedResult.removeAttribute('hidden');
                console.error('CSV fetch error:', err);
              });
          }

          document.querySelectorAll('.hide-on-embed').forEach(el => el.remove());

          if (window.history.replaceState) {
            const cleanUrl = window.location.origin + window.location.pathname;
            window.history.replaceState({}, title || '', cleanUrl);
          }
        })();
      </script>`,
      { html: true }
    )
  }
}