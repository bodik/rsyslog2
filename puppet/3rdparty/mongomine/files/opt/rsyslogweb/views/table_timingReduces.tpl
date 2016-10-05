<html>
<head>
<style type="text/css" title="currentStyle">
@import "datatables/media/css/demo_table.css";
</style>
<script type="text/javascript" language="javascript" src="datatables/media/js/jquery.js"></script>
<script type="text/javascript" language="javascript" src="datatables/media/js/jquery.dataTables.js"></script>
<script type="text/javascript" charset="utf-8">
$(document).ready(function() {
    var oTable = $('#example').dataTable( {
        "bFilter": true,
	"iDisplayLength": 30,
        "aaSorting": [],
        "sAjaxSource": "table_timingReduces_data",
        "aoColumns": [
            { "mDataProp": "name" },
            { "mDataProp": "finished" },
            { "mDataProp": "took" },
            { "mDataProp": "age" },
            { "mDataProp": "ret" }
        ]
    } );
} );

</script>
</head>
<body>
<h2>timingReduces</h2>
total docs: {{total_docs}}
<table cellpadding="0" cellspacing="0" border="0" class="display" id="example" width="100%">
<thead>
	<th>name</th>
	<th>finished</th>
	<th>took</th>
	<th>age</th>
	<th>ret</th>
</thead>
</table>
</body>
</html>
