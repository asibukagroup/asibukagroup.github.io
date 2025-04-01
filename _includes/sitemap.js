document.addEventListener("DOMContentLoaded", function() {
  const filterSelect = document.getElementById("filter");
  const filterInput = document.getElementById("filterInput");
  const postsTableBody = document.getElementById("postsTableBody");

  // Function to filter the posts based on the selected filter and input
  function filterPosts() {
    const filterValue = filterSelect.value.toLowerCase();
    const filterText = filterInput.value.toLowerCase();
    
    const rows = postsTableBody.querySelectorAll(".post-row");

    rows.forEach(function(row) {
      const cells = row.children;
      let shouldShow = false;

      switch (filterValue) {
        case "title":
          shouldShow = cells[1].textContent.toLowerCase().includes(filterText);
          break;
        case "author":
          shouldShow = cells[2].textContent.toLowerCase().includes(filterText);
          break;
        case "date":
          shouldShow = cells[3].textContent.toLowerCase().includes(filterText);
          break;
        case "categories":
          shouldShow = cells[4].textContent.toLowerCase().includes(filterText);
          break;
        case "tags":
          shouldShow = cells[5].textContent.toLowerCase().includes(filterText);
          break;
      }

      if (shouldShow) {
        row.style.display = "";
        highlightSearchText(row, filterText);
      } else {
        row.style.display = "none";
      }
    });
  }

  // Function to highlight search text
  function highlightSearchText(row, searchText) {
    const cells = row.children;
    Array.from(cells).forEach(function(cell) {
      const regex = new RegExp(searchText, 'gi');
      cell.innerHTML = cell.textContent.replace(regex, function(match) {
        return `<span class="highlight">${match}</span>`;
      });
    });
  }

  // Event listeners for filter input and selection change
  filterInput.addEventListener("input", filterPosts);
  filterSelect.addEventListener("change", filterPosts);
});
