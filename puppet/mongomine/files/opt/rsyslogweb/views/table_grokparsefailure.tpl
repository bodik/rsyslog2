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
	"iDisplayLength": 100,
        "sAjaxSource": "table_grokparsefailure_data",
        "aoColumns": [
            { "mDataProp": "_id.$oid" },
            { "mDataProp": "t" },
            { "mDataProp": "@tags" },
            { "mDataProp": "@message",sWidth: '50%' },
        ]
    } );
} );

</script>
</head>
<body>
<h2>_grokparsefailure</h2>
<table cellpadding="0" cellspacing="0" border="0" class="display" id="example" width="100%">
<thead>
	<th>_id.$oid</th>
	<th>t</th>
	<th>@tags</th>
	<th>@message</th>
</thead>
</table>
</body>
</html>
