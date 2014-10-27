<script>
function selectAll(selectBox,selectAll) { 
    // have we been passed an ID 
    if (typeof selectBox == "string") { 
        selectBox = document.getElementById(selectBox);
    } 
    // is the select box a multiple select box? 
    if (selectBox.type == "select-multiple") { 
        for (var i = 0; i < selectBox.options.length; i++) { 
             selectBox.options[i].selected = selectAll; 
        } 
    }
}</script>
<script language="javascript"> 
function toggle(showHideDiv, switchTextDiv) {
	var ele = document.getElementById(showHideDiv);
	var text = document.getElementById(switchTextDiv);
	if(ele.style.display == "block") {
    		ele.style.display = "none";
		text.innerHTML = "show "+showHideDiv;
  	}
	else {
		ele.style.display = "block";
		text.innerHTML = "hide "+showHideDiv;
	}
} 
</script>



% post_data=dict()
%for i in forms:
%	post_data[i] = forms.getall(i)
%       if post_data[i] == ['']:
%		post_data[i] = []
%	end
%end
<div style="font-size:x-small">
<div style="float:left">POST:{{post_data}}</div>
<div style="float:right"><a id="toggleSelectorText" href="javascript:toggle('selectorDiv', 'toggleSelectorText');">hide selectorDiv</a></div>
</div>

<br clear=all>

% selected_results = forms.getall('results')
% selected_methods = forms.getall('methods')
% selected_collection = forms.get('collection')

<div id="selectorDiv" style="display: block">
<table width="100%">
<tr><td>

<form action="search" method="post" name="formUser" id="formUser">
<table>

<tr><td>
timestamp_begin:<input name="timestamp_begin" type="text" size=25 value="{{forms.get('timestamp_begin') or ""}}"/>
<br>
timestamp_end:<input name="timestamp_end" type="text" size=25 value="{{forms.get('timestamp_end') or ""}}"/>
<br>
logsource:<input name="logsource" type="text" value="{{forms.get('logsource') or ""}}"/>
<br>
user:<input name="user" type="text" value="{{forms.get('user') or ""}}"/>
<br>
principal:<input name="principal" type="text" value="{{forms.get('principal') or ""}}"/>
<br>
remote:<input name="remote" type="text" value="{{forms.get('remote') or ""}}"/>
<br>
limit:<input name="limit" type="text" value="{{forms.get('limit') or ""}}"/>
<br>
<input name="submit" value="submit" type="submit" />
</td>

<td>
methods: <select name="methods" size="10" multiple="multiple" id="methods">
%for tmp in methods:
	<option value="{{tmp}}"
	%if tmp in selected_methods:
		selected
	%end
>{{tmp}}</option>
%end
</select>
<input type="button" name="Button1" value="All" onclick="selectAll('methods',true)" />
<input type="button" name="Button2" value="None" onclick="selectAll('methods',false)" />
</td>

<td>
results: <select name="results" size="10" multiple="multiple" id="results">
%for tmp in results:
	<option value="{{tmp}}"
	%if tmp in selected_results:
		selected
	%end
>{{tmp}}</option>
%end
</select>
<input type="button" name="Button1" value="All" onclick="selectAll('results',true)" />
<input type="button" name="Button2" value="None" onclick="selectAll('results',false)" />
</td>

<td>
collection: <select name="collection" size="15">
% for tmp in collections:
	<option value="{{tmp}}"
%	if tmp == selected_collection:
		selected="selected"
%	end
>{{tmp}}</option>
% end
</select>
</td>

</tr>

</table>
</form>

</td><td>


</td></tr>
</table>


</div> <!-- toggle div -->

<hr>
<div style="font-size:x-small">
COLLECTION:{{forms.get('collection',"")}}<br>


% import bson.json_util
% import base64
% b64query = base64.b64encode(bson.json_util.dumps(query))
% data_url = "search_data?query=" + b64query + "&limit=" + str(forms.get('limit',"")) + "&collection="+ forms.get('collection',"")
% gorock_url = "../mongo/rock/index.php?action=collection.index&db=sshd&collection="+forms.get('collection',"")+"&format=json&criteria="+bson.json_util.dumps(query)+"&field[0]=_id&order[0]=desc&limit=0&pagesize=10&command=findAll"
QUERY:<a href="{{data_url}}">{{query}}</a> <a href="{{gorock_url}}">gorock</a><br>
FOUND:{{found}}<br>
</div><p>


% if (found > 0):

<style type="text/css" title="currentStyle">@import "datatables/media/css/demo_table.css";</style>
<script type="text/javascript" language="javascript" src="datatables/media/js/jquery.js"></script>
<script type="text/javascript" language="javascript" src="datatables/media/js/jquery.dataTables.js"></script>
<script type="text/javascript" charset="utf-8">
$(document).ready(function() {
        $.ajax( {
                "dataType": 'json',
                "type": "GET",
                "url": "{{data_url}}",
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

% end
