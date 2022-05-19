$(document).on('turbolinks:load', function() {
  const tableSelectors = '#purpose-travel-patterns-table, #funding-sources-table';

  let dataTable = $(tableSelectors).DataTable({
    "columnDefs": [ {
      "targets": 2,
      "orderable": false
    } ]
  });

  document.addEventListener("turbolinks:before-cache", function() {
    if (dataTable !== null) {
     dataTable.destroy();
     dataTable = null;
    }
  });
});