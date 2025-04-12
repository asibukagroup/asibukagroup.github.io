<script>//Dark Mode
const body=document.body,darkToggle=document.getElementById("darkToggle");"enabled"===localStorage.getItem("dark-mode")&&body.classList.add("dark"),darkToggle.addEventListener("click",()=>{body.classList.toggle("dark"),localStorage.setItem("dark-mode",body.classList.contains("dark")?"enabled":"disabled")});
// PWA
"serviceWorker"in navigator&&navigator.serviceWorker.register("/sw.js").then(e=>console.log("Service Worker Registered!",e)).catch(e=>console.log("Service Worker Registration Failed!",e));
// Random Posts
fetch('{{ "/search.json" | relative_url }}').then(n=>n.json()).then(n=>{0!==n.length&&(n=n[Math.floor(Math.random()*n.length)],window.randomLink=n.url)}).catch(console.error);
// Lazyload Scripts
function lazyLoadScript(n,c,e){var i=!1;function t(){if(!i){i=!0;var e,t=document.createElement("script");for(e in t.src=n,t.async=!0,c)c.hasOwnProperty(e)&&t.setAttribute(e,c[e]);document.head.appendChild(t)}}c=c||{},"scroll"===(e=e||"click")?window.addEventListener("scroll",t,{once:!0}):"timeout"===e?setTimeout(t,3e3):(window.addEventListener("click",t,{once:!0}),window.addEventListener("touchstart",t,{once:!0}))}
// Lazyload AdSense
lazyLoadScript("https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-4951061355072034",{crossorigin:"anonymous"});
</script>