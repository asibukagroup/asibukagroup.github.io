//Dark Mode
document.addEventListener("DOMContentLoaded",function(){const e=document.getElementById("dark-mode-toggle"),t=document.body;"enabled"===localStorage.getItem("dark-mode")&&(t.classList.add("dark-mode"),e.textContent="☀️"),e.addEventListener("click",function(){t.classList.toggle("dark-mode"),t.classList.contains("dark-mode")?(localStorage.setItem("dark-mode","enabled"),e.textContent="☀️"):(localStorage.setItem("dark-mode","disabled"),e.textContent="🌙")})});
//Sidebar
const hamburger=document.getElementById("hamburger-menu"),sidebar=document.getElementById("sidebar"),closeSidebar=document.getElementById("close-sidebar"),overlay=document.getElementById("overlay");hamburger.addEventListener("click",()=>{sidebar.classList.add("open"),overlay.classList.add("show")}),closeSidebar.addEventListener("click",()=>{sidebar.classList.remove("open"),overlay.classList.remove("show")}),overlay.addEventListener("click",()=>{sidebar.classList.remove("open"),overlay.classList.remove("show")});
// PWA
"serviceWorker"in navigator&&navigator.serviceWorker.register("/sw.js").then(e=>console.log("Service Worker Registered!",e)).catch(e=>console.log("Service Worker Registration Failed!",e));
