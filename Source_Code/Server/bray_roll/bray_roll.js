
/*
	Takes json, parses into new_roll, then scans new_roll to see if there
	are any new elements that weren't in the old roll. if such is found, 
	call an AJAX fxn to add it to the html page and add it to roll 
*/
var roll = {"users":[]};

function executeQuery() {
  $.ajax({
    url: 'bray_roll.json',
    success: function(data) {
    	var new_roll = data;
    	for (var e in roll.users) {
    		if ($.inArray(e, new_roll.users) == -1){ 
  	    		//if an old element is not in new_roll{}, take it out of HTML page and array
  	    	removeUserHTML(e);
  				var index = roll.users.indexOf(e);
  				roll.users.splice(index, 1);
  			}
    	}
    	for (var e in new_roll.users) {
    		if ($.inArray(e, roll.users) == -1){ 
	    		//if the new element is not in roll{}, add it to HTML and roll.users
	    		addUserHTML(e);
          console.log(e);
	    		roll.users.push(e)
    		}
    	}
    }
  });
  setTimeout(executeQuery, 10000);
}

$(document).ready(function() {
  // run executeQuery first time; all subsequent calls will take care of themselves
  setTimeout(executeQuery, 5000);
});

function addUserHTML(e) {
  console.log('in add user html');
  console.log(e);
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