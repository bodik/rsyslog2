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
	"iDisplayLength": 20,
        "aaSorting": [],
        "sAjaxSource": "table_mapResult_data",
        "aoColumns": [
            { "mDataProp": "_id.result" },
            { "mDataProp": "value.count" }
        ]
    } );
} );

</script>
</head>
<body>
<h2>mapResult</h2>
<table cellpadding="0" cellspacing="0" border="0" class="display" id="example" width="100%">
<thead>
	<th>_id.result</th>
	<th>value.count</th>
</thead>
</table>
</body>
</html>
