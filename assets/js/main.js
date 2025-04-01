let lastScrollTop = 0;
const header = document.getElementById("site-header");

window.addEventListener("scroll", function() {
    let scrollTop = window.scrollY || document.documentElement.scrollTop;
    
    if (scrollTop > lastScrollTop) {
        // Scrolling down, hide header
        header.classList.add("header-hidden");
    } else {
        // Scrolling up, show header
        header.classList.remove("header-hidden");
    }
    
    lastScrollTop = scrollTop;
});
