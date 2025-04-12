<script>//Dark Mode
const body=document.body,darkToggle=document.getElementById("darkToggle");"enabled"===localStorage.getItem("dark-mode")&&body.classList.add("dark"),darkToggle.addEventListener("click",()=>{body.classList.toggle("dark"),localStorage.setItem("dark-mode",body.classList.contains("dark")?"enabled":"disabled")});
// PWA
"serviceWorker"in navigator&&navigator.serviceWorker.register("/sw.js").then(e=>console.log("Service Worker Registered!",e)).catch(e=>console.log("Service Worker Registration Failed!",e));
// Random Posts
const postUrls=[{% for post in site.posts %}{% unless post.url contains '/404.html' or post.url contains '/search.json' or post.url contains '/amp/' %}"{{ post.url | relative_url }}",{% endunless %}{% endfor %}],randomUrl=postUrls[Math.floor(Math.random()*postUrls.length)];document.addEventListener("DOMContentLoaded",function(){const n=document.getElementById("random-post-link");n&&randomUrl&&(n.href=randomUrl)});
// Lazyload
Defer.dom('.lazy,.lazyload',0,'loaded',function(){console.log('Lazy loaded');},{rootMargin:'1px'});
// Lazyload Scripts
function lazyLoadScript(n,c,e){var i=!1;function t(){if(!i){i=!0;var e,t=document.createElement("script");for(e in t.src=n,t.async=!0,c)c.hasOwnProperty(e)&&t.setAttribute(e,c[e]);document.head.appendChild(t)}}c=c||{},"scroll"===(e=e||"click")?window.addEventListener("scroll",t,{once:!0}):"timeout"===e?setTimeout(t,3e3):(window.addEventListener("click",t,{once:!0}),window.addEventListener("touchstart",t,{once:!0}))}
// Lazyload AdSense
lazyLoadScript("https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-4951061355072034",{crossorigin:"anonymous"});
</script>