<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<script type='text/javascript' src='static/jquery-1.9.1.js'></script>
<script type='text/javascript'>
$(function() {
	Highcharts.setOptions({	global: { useUTC: false } });
	$.getJSON("graph_mapLogPerX_data?per={{per}}", function(data){ 
		$('#container').highcharts({
		        chart: { type: 'line', animation: false },
			title: { floating: true, text: "mapLogPer{{per}}" },
		        xAxis: { type: 'datetime',
				dateTimeLabelFormats: {
					millisecond: '%d-%m %H:%M',
					second: '%d-%m %H:%M',
					minute: '%d-%m %H:%M',
					hour: '%d-%m %H:%M',
					day: '%d-%m %H:%M',
					week: '%d-%m %H:%M',
					month: '%d-%m %H:%M',
					year: '%d-%m %H:%M'
				}
			},
			tooltip: {formatter: function() { return Highcharts.dateFormat('%d-%m %H:%M', this.x) +'<br>'+this.series.name+':'+this.y;}, animation:false },
		        yAxis: { title: { text: null }, type: "logarithmic" },
			legend: { align: "right", verticalAlign: "middle", layout: "vertical"},
			credits: { enabled: false},
			plotOptions: { series: { animation: false}},
		        series: data
		    });
	});
});
</script>
</head>
<body>
<script src="static/highcharts.js"></script>
<script src="static/exporting.js"></script>
<div id="container" style="width: 100%; height: 100%;"></div>
</body>
</html>

