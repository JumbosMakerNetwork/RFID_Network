<?php

// test url: http://130.64.17.0/RFID.php?sid=1&rfid=123456789&req=1&info=none
// Expected get items 
// Every time: rfid, sid, req
// Sometimes: info (Only used when sending feedback info on use)

// echo "So this is the start of the thing <br />";

if( $_GET['rfid'] and $_GET['sid'] and $_GET['req'])
{
  // Strip 
  $rfid = strip_tags($_GET['rfid']);
  $sid = strip_tags($_GET['sid']);
  $req = strip_tags($_GET['req']);
  $remote = $_SERVER['REMOTE_ADDR'];

  // Determine IP of the terminal sending the GET request. 
  $ip = get_ip();

  date_default_timezone_set("EST");
  // echo 'Now:       '. date('H:i:s', time())."<br />";
  // echo "Recieved a type $req GET request from some source $ip <br />";

  // open db connection
  $link = pg_Connect("host=localhost dbname=JMN_DEV user=jumbo password=jumbo_pw7");

  // Determine the uid from rfid
  list($uid,$fname) = getuid($rfid, $link);

  if ($req == 1) // Terminal is accessing for permission and expecting a response
  {
    // echo "<p>Type 1 request... <br />";
    $info = 'N/A';
    // query for access
    $result = pg_exec($link, "SELECT access from permissions WHERE sid = '$sid' AND uid='$uid'");
    $numrows = pg_numrows($result);
  
    // if query returns any rows
    if ($numrows > 0)
    {
      // get data
      $row = pg_fetch_array($result, 0);
      $resp = $row['access'];

      // if access is allowed
      if ($resp == "t") 
      {
        $response = "T";
        // echo "Access Granted. Congrats $fname! <br />";
        pg_exec($link, "UPDATE permissions SET uses = uses+1 WHERE sid=$sid and uid=$uid");
        pg_exec($link, "UPDATE permissions SET luse = current_timestamp WHERE sid=$sid and uid=$uid");
      } 
      else 
      {
        $response = "F";
        // echo "Access: <br />";
      }
    }
    else // access is not allowed
    {
      $response = "E";
      // echo "Error";
    }
  }
  elseif ($req == 2)
  {
    $response = 'N';
    // echo "<p>Type 2 request... <br />";
    if( $_GET['info'] )
    {
      $info = $_GET['info'].' seconds';
      pg_exec($link, "UPDATE permissions SET time_used = time_used + INTERVAL '$info' WHERE sid=1 and uid=1");
    }
    else
    {
      $info = "No info sent";
    }
  }

  echo "Access-$response Name-$fname";

  // Logging inquiry 
  // echo "<p>Logging inquiry and response... <br />";
  // echo "INSERT INTO log VALUES (default, default, $uid, $sid, $req, '$response', '$info')";
  pg_exec($link, "INSERT INTO usage_log VALUES (default, default, $uid, $sid, $req, '$response', '$info', '$ip')");

  exit();

}

// else
// {
//   // open db connection
//   $link = pg_Connect("host=localhost dbname=JMN user=boconn password=madison46");
//   echo "<p>Incorrect GET requests detected "
//   echo "<p>Logging inquiry and response ";
//   Need to add logging capabilities for each scenerio (Incorrect sid, No RFID, neither, etc)
// }

// Get user ID and fname from their RFID
function getuid($the_rfid, $link) 
{
  $uidreq = pg_exec($link, "SELECT uid, fname from users WHERE rfid='$the_rfid'");
  $nrows = pg_numrows($uidreq);

  if ($nrows > 0)
  {
    $row = pg_fetch_array($uidreq, 0);
    $the_uid = $row['uid'];
    $the_fname = $row['fname'];
    // echo "User ID # is $the_uid <br />";
    // echo "User name is $the_fname <br />";
    return array($the_uid, $the_fname);
  }
  else
  {
    // echo "UID error.";
    return "000";
  }

}




// Function to determine the IP of the terminal sending the GET request. 
function get_ip() {
    //Just get the headers if we can or else use the SERVER global
    if ( function_exists( 'apache_request_headers' ) ) {
      $headers = apache_request_headers();
    } else {
      $headers = $_SERVER;
    }
    //Get the forwarded IP if it exists
    if ( array_key_exists( 'X-Forwarded-For', $headers ) && filter_var( $headers['X-Forwarded-For'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 ) ) {
      $the_ip = $headers['X-Forwarded-For'];
    } elseif ( array_key_exists( 'HTTP_X_FORWARDED_FOR', $headers ) && filter_var( $headers['HTTP_X_FORWARDED_FOR'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 )
    ) {
      $the_ip = $headers['HTTP_X_FORWARDED_FOR'];
    } else {
      $the_ip = filter_var( $_SERVER['REMOTE_ADDR'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 );
    }
    return $the_ip;
  }



?>
<html>
<body>
  <form action="<?php $_PHP_SELF ?>" method="GET">
  Name: <input type="text" name="rfid" />
  Age: <input type="text" name="sid" />
  <input type="submit" />
  </form>
</body>
</html>







