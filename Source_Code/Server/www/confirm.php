<?php
	if($_GET['name'])
	{
		$name = strip_tags($_GET['name']);
	}
?>

<!DOCTYPE html>
<html lang="en">
	<head>
    	<meta charset="utf-8">
    	<meta http-equiv="X-UA-Compatible" content="IE=edge">
    	<meta name="viewport" content="width=device-width, initial-scale=1">
    	<meta name="description" content="Jumbo's Maker Network Confirmation Page">
    	<meta name="author" content="Brian O'Connell">
    	<title>Jumbo's Maker Network - Confirmation</title>
  	</head>
	<body>
		<h1>Welcome <?php echo "$name" ?></h1>
		<p>Thank you for signing up for Jumbo's Maker Network.</p>
	</body>
</html>



