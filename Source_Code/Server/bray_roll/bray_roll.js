
/*
	Takes json, parses into new_roll, then scans new_roll to see if there
	are any new elements that weren't in the old roll. if such is found, 
	call an AJAX fxn to add it to the html page and add it to roll 
*/
var roll = {"users":[]};
var workers = ["Marya", "Ben"]

function executeQuery() {
  $.ajax({
    url: 'bray_roll.json',
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
  var color = "";
  if($.inArray("13", e.permissions)){
        color = "success";
        permission = "Green";
  }if($.inArray("14", e.permissions))
        color = "warning";
        permission = "Yellow";
  if($.inArray("15", e.permissions)){
        color = "danger";
        permission = "Red";
  }  
  if($.inArray(e.firstName, workers)){
        color = "info";
        permission = "Worker";
  }
	$('#roll_table_body').append('<tr class="'+color+'"id="'+e.timeArrived+'"><td>'+e.firstName+' '+e.lastName+'</td><td>'+e.timeArrived+'</td><td>'+permission+'</tr>');
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