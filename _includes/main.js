//Dark Mode
document.addEventListener("DOMContentLoaded", function () {
            const darkModeToggle = document.getElementById("dark-mode-toggle");
            const body = document.body;

            if (localStorage.getItem("dark-mode") === "enabled") {
                body.classList.add("dark-mode");
                darkModeToggle.textContent = "☀️";
            }

            darkModeToggle.addEventListener("click", function () {
                body.classList.toggle("dark-mode");
                if (body.classList.contains("dark-mode")) {
                    localStorage.setItem("dark-mode", "enabled");
                    darkModeToggle.textContent = "☀️";
                } else {
                    localStorage.setItem("dark-mode", "disabled");
                    darkModeToggle.textContent = "🌙";
                }
            });
        });
//Sidebar
const hamburger = document.getElementById("hamburger-menu");
    const sidebar = document.getElementById("sidebar");
    const closeSidebar = document.getElementById("close-sidebar");
    const overlay = document.getElementById("overlay");

    // Open Sidebar
    hamburger.addEventListener("click", () => {
        sidebar.classList.add("open");
        overlay.classList.add("show");
    });

    // Close Sidebar
    closeSidebar.addEventListener("click", () => {
        sidebar.classList.remove("open");
        overlay.classList.remove("show");
    });

    // Close Sidebar When Clicking Outside
    overlay.addEventListener("click", () => {
        sidebar.classList.remove("open");
        overlay.classList.remove("show");
    });
