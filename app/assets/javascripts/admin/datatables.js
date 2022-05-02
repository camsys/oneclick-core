$(document).ready(function() {
  $('#purpose-travel-patterns-table').DataTable({
    "columnDefs": [ {
      "targets": 2,
      "orderable": false
    } ]
  });
});