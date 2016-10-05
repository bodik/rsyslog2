<style type="text/css" title="currentStyle">@import "datatables/media/css/demo_table.css";</style>
<script type="text/javascript" language="javascript" src="datatables/media/js/jquery.js"></script>
<script type="text/javascript" language="javascript" src="datatables/media/js/jquery.dataTables.js"></script>
<script type="text/javascript" charset="utf-8">
$(document).ready(function() {
        $.ajax( {
                "dataType": 'json',
                "type": "GET",
                "url": "alerts_data",
                "success": function (data) {
                        $('#example').dataTable({
			        "bFilter": true,
			        "iDisplayLength": 100,
			        "aaSorting": [],
				"bAutoWidth": false,
                                "aaData": data.aaData,
                                "aoColumns": data.aoColumns,
				"fnInitComplete": function() { $('#processingDiv').hide();}
                        });
                }
        } );
});
</script>
<div id="processingDiv">loading data ...</div>
<table cellpadding="0" cellspacing="0" border="0" class="display" id="example" width="100%"></table>

