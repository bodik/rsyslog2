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


% hostname = forms.get("hostname", "")
% remote = forms.get("remote", "")

<form action="profile_remote">
	hostname: <input type=text name="hostname" value="{{hostname}}">
	remote: <input type=text name="remote" value="{{remote}}">
	<input type="submit" name="submit" value="submit">
</form>
<hr>

% if remote:

<table width="100%">
<tr><td width="80%">

<script>
function change_graph(id, newval) {
	iframe = document.getElementById(id);
	iframe.src=newval;
}</script>
<a href="#" onclick="change_graph('graph_mapRemoteResultPerX', 'graph_mapRemoteResultPerX?per=Hour&remote={{remote}}');">Hour</a>
<a href="#" onclick="change_graph('graph_mapRemoteResultPerX', 'graph_mapRemoteResultPerX?per=Day&remote={{remote}}');">Day</a>
<a href="#" onclick="change_graph('graph_mapRemoteResultPerX', 'graph_mapRemoteResultPerX?per=Month&remote={{remote}}');">Month</a>
<iframe id="graph_mapRemoteResultPerX" src="graph_mapRemoteResultPerX?per=Day&remote={{remote}}" width="100%" height="200"></iframe>

</td><td>

remote: {{remote}} -- hostname: {{hostname}} -- {{listed}}
<p>
% for i in profile['remoteresult']:
	{{i["_id"]["result"]}} -- {{i["value"]["count"]}}<br>
% end
<div><a id="toggleSelectorText" href="javascript:toggle('geoDiv', 'toggleSelectorText');">geoDiv</a></div>
<div id="geoDiv" style="display: none">
{{profile['geo']}}
</div>

% if "wardenlisted" in listed:
	<a href="/mongo/rock/index.php?db=warden&collection=events&action=collection.index&format=json&criteria={%0D%0A%22source%22%3A%22{{remote}}%22%0D%0A}&limit=0&command=findAll">warden</a>
% end

<p>
<a href="/kibana3/index.html#/dashboard/file/sshprofile.json?remote={{remote}}">kibana3 profile</a>
<a href="https://apps.db.ripe.net/search/query.html?searchtext={{remote}}&searchSubmit=search#resultsAnchor">ripe::{{remote}}</a>
<a href="http://isc.sans.edu/ipinfo.html?ip={{remote}}">sans.org::{{remote}}</a>
<p>
<a href="cracks_whitelist?remote={{remote}}">whitelist</a>
<a href="cracks_blacklist?remote={{remote}}">blacklist</a>

</td></tr>
</table>

<iframe src="search?remote={{remote}}&submit=1" width="100%" height="100%"></iframe>

% end #ifremote

