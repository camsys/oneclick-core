$(document).on('turbolinks:load', function() {
  const tableSelectors = '#purpose-travel-patterns-table, #funding-sources-table, #booking-profiles-table';

  if ($.fn.DataTable.isDataTable(tableSelectors)) {
    $(tableSelectors).DataTable().destroy();
  }

  let dataTable = $(tableSelectors).DataTable({
    "columnDefs": [ {
      "targets": 2,
      "orderable": false
    } ]
  });

  document.addEventListener("turbolinks:before-cache", function() {
    if ($.fn.DataTable.isDataTable(tableSelectors)) {
      dataTable.destroy();
      dataTable = null;
    }
  });
});
