//Dark Mode
document.addEventListener("DOMContentLoaded",function(){const e=document.getElementById("dark-mode-toggle"),t=document.body;"enabled"===localStorage.getItem("dark-mode")&&(t.classList.add("dark-mode"),e.textContent="☀️"),e.addEventListener("click",function(){t.classList.toggle("dark-mode"),t.classList.contains("dark-mode")?(localStorage.setItem("dark-mode","enabled"),e.textContent="☀️"):(localStorage.setItem("dark-mode","disabled"),e.textContent="🌙")})});
// Floating Menu
let lastScrollTop=0;const navbar=document.querySelector(".floating-navbar");window.addEventListener("scroll",function(){var a=window.pageYOffset||document.documentElement.scrollTop;a>lastScrollTop?(navbar.style.transform="translate(-50%, -100%)",navbar.style.opacity="0"):(navbar.style.transform="translate(-50%, 0)",navbar.style.opacity="1"),lastScrollTop=a});
//Sidebar
const hamburger=document.getElementById("hamburger-menu"),sidebar=document.getElementById("sidebar"),closeSidebar=document.getElementById("close-sidebar"),overlay=document.getElementById("overlay");hamburger.addEventListener("click",()=>{sidebar.classList.add("open"),overlay.classList.add("show")}),closeSidebar.addEventListener("click",()=>{sidebar.classList.remove("open"),overlay.classList.remove("show")}),overlay.addEventListener("click",()=>{sidebar.classList.remove("open"),overlay.classList.remove("show")});
// PWA
"serviceWorker"in navigator&&navigator.serviceWorker.register("/sw.js").then(e=>console.log("Service Worker Registered!",e)).catch(e=>console.log("Service Worker Registration Failed!",e));
