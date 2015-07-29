<?php
    if (isset($_POST['JMN_ID']))   
    {
        $errJMN_ID = '$JMN_ID was not found in database';
    }
    // if (isset($_POST["submit"])) {
    //     $JMN_ID = $_POST['JMN_ID'];

    //     echo "Blah blah blah";

    //     // Check if class has been entered and is valid
    //     if (!$_POST['JMN_ID']) {
    //         $errJMN_ID = 'Please enter a valid JMN username';
    //     }
    // }
?>


<!DOCTYPE html>
<html lang="en">
    <head>
        <!-- <meta charset="utf-8"> -->
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="description" content="Signup form for Jumbo's Maker Network">
        <meta name="author" content="Brian O'Connell">
        <title>Jumbo's Maker Network - RFID Addition</title>
        <!-- <link rel="stylesheet" href="main.css"> -->
        <style>
            h1 {position: relative; vertical-align:baseline; line-height: 1.25em; 
                font-size:36px; font-weight: 400; margin-bottom: .5em; 
                z-index:1; text-align:center}
            form {display: block; position: relative; text-align:center; font-size:24px}
            input {color:blue; position: relative; text-align:center; font-size:18px}
            error {color:red; font-size:18px}
        </style>
    </head>
    <body>
        <h1>Get Your Jumbo's Maker Network RFID</h1>
        <form class="form-horizontal" method="post" action="Add_RFID.php">
            <!-- <div class="form_group"> -->
                <label for="JMN_ID" >Enter your JMN Username</label>
                <!-- <div class="form_input"> -->
                    <input type="text" id="JMN_ID" name="JMN_ID" autofocus="autofocus" placeholder="JMN Username" value="<?php echo htmlspecialchars($_POST['JMN_ID']); ?>">
                    <error><?php echo "<p>$errJMN_ID</p>";?></error>
                <!-- </div> -->
            <!-- </div> -->
        </form>
    </body>
</html>






<!--         <div class="form-group">
                        <label for="fname" class="col-sm-2 control-label">First Name</label>
                        <div class="col-sm-10">
                            <input type="text" class="form-control" id="fname" name="fname" placeholder="First Name" value="<?php echo htmlspecialchars($_POST['fname']); ?>">
                            <?php echo "<p class='text-danger'>$errfName</p>";?>
                        </div>
                    </div> -->




<!-- 
<form method="post" action="form2.php">
    <input type="text" name="name">
    <input type="text" name="email_address">
    <input type="submit" value="Go To Step 2">
</form> -->






