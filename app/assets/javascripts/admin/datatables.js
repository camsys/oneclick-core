$(document).ready(function() {
  const tableSelectors = '#purpose-travel-patterns-table, #funding-sources-table';

  $(tableSelectors).DataTable({
    "columnDefs": [ {
      "targets": 2,
      "orderable": false
    } ]
  });
});