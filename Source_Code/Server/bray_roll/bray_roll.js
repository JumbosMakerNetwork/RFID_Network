
/*
	Takes json, parses into new_roll, then scans new_roll to see if there
	are any new elements that weren't in the old roll. if such is found, 
	call an AJAX fxn to add it to the html page and add it to roll 
*/
var roll = {"users":[]};

function executeQuery() {
  $.ajax({
    url: 'bray_roll.json',
    success: function(new_roll) {
      flushUserHTML();
    	for (var i in new_roll.users) {
	    		addUserHTML(new_roll.users[i]);
    	}
    }
  });
  setTimeout(executeQuery, 10000);
}

$(document).ready(function() {
  // run executeQuery first time; all subsequent calls will take care of themselves
  setTimeout(executeQuery, 5000);
});

funciton flushUserHTML(){

}
function addUserHTML(e) {
	$('#roll_table').append('<tr id="'+e.timeArrived+'"><td>'+e.firstName+' '+e.lastName+'</td><td>'+e.timeArrived+'</td><td>'+e.expertise+'</tr>');
}
function removeUserHTML(e) {
	$('#'+e.timeArrived).remove();
}



//Format of json object
/*
{"users":[
    {"firstName":"John", "lastName":"Doe", "timeArrived":"Mon Jun 06 2016 09:25:33", "expertise": ["Laser Cutter","CNC"]},
    {"firstName":"Anna", "lastName":"Smith", "timeArrived":"Mon Jun 06 2016 09:25:33", "expertise": ["3D printer","CNC"]},
    {"firstName":"Peter", "lastName":"Jones", "timeArrived":"Mon Jun 06 2016 09:25:33", "expertise": ["Play-Doh","CNC"]}
]}
*/