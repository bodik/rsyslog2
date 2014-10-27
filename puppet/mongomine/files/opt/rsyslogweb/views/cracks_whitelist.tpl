<form action="cracks_whitelist_add" action=GET>
remote: <input type="text" name="remote" value="{{remote}}">
<br>
note: <textarea name="note"></textarea>
<input type="submit" name="submit" value="submit">
</form>

<hr>

% for i in data:
	{{i['remote']}} -- {{i['note']}} -- {{i['owner']}} -- <a href="cracks_whitelist_del?remote={{i['remote']}}">del</a><br>
	<hr>
% end
