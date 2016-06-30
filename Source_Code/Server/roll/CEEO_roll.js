
/*
	Takes json, parses into new_roll, then scans new_roll to see if there
	are any new elements that weren't in the old roll. if such is found, 
	call an AJAX fxn to add it to the html page and add it to roll 
*/
var roll = {"users":[]};

function executeQuery() {
  $.ajax({
    url: 'CEEO_roll.json',
    success: function(new_roll) {
      flushUserHTML();
    	for (var i in new_roll) {
	    		addUserHTML(new_roll[i]);
    	}
    }
  });
  setTimeout(executeQuery, 5000);
}

$(document).ready(function() {
  // run executeQuery first time; all subsequent calls will take care of themselves
  executeQuery();
});

function flushUserHTML(){
  $('#roll_table_body').empty();
}
function addUserHTML(e) {
  var color;
  if(e.permissions.length > 0) {
        color = "success";
  }    
  else  color = "warning";

	$('#roll_table_body').append('<tr class="'+color+'"id="'+e.timeArrived+'"><td>'+e.firstName+' '+e.lastName+'</td><td>'+e.timeArrived+'</td><td>'+e.permissions+'</tr>');
}
function removeUserHTML(e) {
	$('#'+e.timeArrived).remove();
}



//Format of json object
/*
{"19":{"firstName":"Will","lastName":"Dolan","timeArrived":"01:06:52pm","permissions":["S","S"]}}

*/