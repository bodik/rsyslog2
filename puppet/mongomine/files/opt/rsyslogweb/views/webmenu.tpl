<html>
<head><style>ul,li { display:inline; padding: 5px;} body { font-size: 0.8em; }</style></head>
<body>
<ul>

% menu = ["stats", "search", "profile_remote", "dropmaps", "table_grokparsefailure", "table_mapCrackers", "table_timingReduces", "cracks_list", "alerts", "cracks_whitelist", "cracks_blacklist", "warden_list", "tor_list"]
% for i in menu:
 <li><a href="{{i}}" target="content">{{i}}</a></li>
% end

<li><a href="../rock" target="content">rock</a></li>

</ul>
</body>
</html>
	
