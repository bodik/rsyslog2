Total: {{len(wardenlist)}}
<ol>
% for i in wardenlist:
<li><a href="profile_remote?remote={{i}}">{{i}}</a></li>
% end
</ol>
