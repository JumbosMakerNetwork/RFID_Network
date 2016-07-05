$(document).ready(function(){
		var canvas = document.getElementById("usage_graph");
		var ctx = canvas.getContext("2d");

		$.ajax({
			type:'get',
		    url:"python/monthly_log_count.txt",
		    cache:false,
		    dataType:"text", 
		}).done(function(log_count) {
			$.ajax({
				type:'get',
			    url:"python/user_signup_monthly.txt",
			    cache:false,
			    dataType:"text", 
			}).done(function(user_count) {
	  			makeGraph(log_count, user_count);
			});
		});
});

function makeGraph(log_count, user_count) {

	// remove first pesky "["
	log_count = log_count.substr(1);
	user_count = user_count.substr(1);

	// split the file data string into an array
	var data_array1 = log_count.split(",");
	var data_array2 = user_count.split(",");
	var len = data_array1.length;
	for (var i = 0; i < len; i++) {
			data_array1[i] = parseInt(data_array1[i]);
			data_array2[i] = parseInt(data_array2[i]);
	}
	console.log(data_array1);
	console.log(data_array2);
	//for now not showing the last two elements, july and aug
	data_array1.pop(); data_array1.pop();
	data_array2.pop(); data_array2.pop();
	console.log(data_array1);
	console.log(data_array2);

	var graph_data = {
	    labels: ["September", "October", "November", "December", "January", "February", "March", "April", "May", "June"],
	    datasets: [
	        {
	            label: "Usage Log per Month",
	            fillColor: "rgba(102,255,102,0.2)",
	            strokeColor: "rgba(102,255,102,1)",
	            pointColor: "rgba(102,255,102,1)",
	            pointStrokeColor: "#fff",
	            pointHighlightFill: "#fff",
	            pointHighlightStroke: "rgba(102,255,102,1)",
	            data: data_array1
	        },
	        {
	            label: "User Signups per Month",
	            fillColor: "rgba(151,187,205,0.2)",
	            strokeColor: "rgba(151,187,205,1)",
	            pointColor: "rgba(151,187,205,1)",
	            pointStrokeColor: "#fff",
	            pointHighlightFill: "#fff",
	            pointHighlightStroke: "rgba(151,187,205,1)",
	            data: data_array2
	        }
	    ]
	};
	var ctx = document.getElementById("usage_graph").getContext("2d");
	var myLineChart = new Chart(ctx).Line(graph_data, graph_options);
}
