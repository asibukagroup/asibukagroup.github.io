//Dark Mode
document.addEventListener("DOMContentLoaded",function(){const e=document.getElementById("dark-mode-toggle"),t=document.body;"enabled"===localStorage.getItem("dark-mode")&&(t.classList.add("dark-mode"),e.textContent="☀️"),e.addEventListener("click",function(){t.classList.toggle("dark-mode"),t.classList.contains("dark-mode")?(localStorage.setItem("dark-mode","enabled"),e.textContent="☀️"):(localStorage.setItem("dark-mode","disabled"),e.textContent="🌙")})});
// Floating Menu
let lastScrollTop=0;const navbar=document.querySelector(".floating-navbar");window.addEventListener("scroll",function(){var a=window.pageYOffset||document.documentElement.scrollTop;a>lastScrollTop?(navbar.style.transform="translate(-50%, -100%)",navbar.style.opacity="0"):(navbar.style.transform="translate(-50%, 0)",navbar.style.opacity="1"),lastScrollTop=a});
/// PWA
"serviceWorker"in navigator&&navigator.serviceWorker.register("/sw.js").then(e=>console.log("Service Worker Registered!",e)).catch(e=>console.log("Service Worker Registration Failed!",e));
// Lazyload Scripts
function lazyLoadScript(n,c,e){var i=!1;function t(){if(!i){i=!0;var e,t=document.createElement("script");for(e in t.src=n,t.async=!0,c)c.hasOwnProperty(e)&&t.setAttribute(e,c[e]);document.head.appendChild(t)}}c=c||{},"scroll"===(e=e||"click")?window.addEventListener("scroll",t,{once:!0}):"timeout"===e?setTimeout(t,3e3):(window.addEventListener("click",t,{once:!0}),window.addEventListener("touchstart",t,{once:!0}))}
// Lazyload AdSense
lazyLoadScript("https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-4951061355072034",{crossorigin:"anonymous"});