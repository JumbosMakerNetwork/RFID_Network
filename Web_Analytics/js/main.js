$(document).ready(function(){
		var canvas = document.getElementById("usage_graph");
		var ctx = canvas.getContext("2d");

		$.ajax({
			type:'get',
		    url:"python/test.py",
		    cache:false,
		    dataType:"text", 
		}).done(function( result ) {
		   	  var myLineChart = new Chart(ctx).Line(graph_data, graph_options);
		   	  $("#test").html(result);
		});
});