$(document).ready(function(){
		var canvas = document.getElementById("usage_graph");
		var ctx = canvas.getContext("2d");

		$.ajax({
			type:'get',
		    url:"python/monthly_log_count.txt",
		    cache:false,
		    dataType:"text", 
		}).done(makeGraph(file_data));
});

makeGraph(file_data) {

	// split the file data string into an array
	var data_array = file_data.split(",");
	var len = data_array.length;
	for (var i = 0; i < len; i++) {
			data_array[i] = parseInt(data_array[i]);
	}

	var graph_data = {
	    labels: ["September", "October", "November", "December", "January"],
	    datasets: [
	        {
	            label: "My First dataset",
	            fillColor: "rgba(220,220,220,0.2)",
	            strokeColor: "rgba(220,220,220,1)",
	            pointColor: "rgba(220,220,220,1)",
	            pointStrokeColor: "#fff",
	            pointHighlightFill: "#fff",
	            pointHighlightStroke: "rgba(220,220,220,1)",
	            data: data_array
	        },
	        {
	            label: "My Second dataset",
	            fillColor: "rgba(151,187,205,0.2)",
	            strokeColor: "rgba(151,187,205,1)",
	            pointColor: "rgba(151,187,205,1)",
	            pointStrokeColor: "#fff",
	            pointHighlightFill: "#fff",
	            pointHighlightStroke: "rgba(151,187,205,1)",
	            data: [28, 48, 40, 19, 86]
	        }
	    ]
	};
	var myLineChart = new Chart(ctx).Line(graph_data, graph_options);
}
