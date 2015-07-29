<?php
	$link1 = pg_Connect("host=localhost dbname=JMN_DEV user=jumbo password=jumbo_pw7");
	$result1 = pg_query($link1, "SELECT * FROM departments");
	$depts = pg_fetch_all($result1); // Grabs an array from the database
	$result2 = pg_query($link1, "SELECT * FROM relationship");
	$Rships = pg_fetch_all($result2);
	$youngest = date("Y") - 17; 
	$Rogers = date("Y") - 75;
	$current_class = date("Y") + 5;
	$Class_YEARS = range(date("Y"),$current_class);
	$years = range($youngest, $Rogers);
	pg_close($link1);

	if (isset($_POST["submit"])) {
		$uname = $_POST['uname'];
		$fname_tmp = $_POST['fname'];
		$fname = pg_escape_string($fname_tmp);
		$lname_tmp = $_POST['lname'];
		$lname = pg_escape_string($lname_tmp);
		$email = $_POST['email'];
		$Temail = $_POST['Temail'];
		$dept = $_POST['dept'];
		$byear = $_POST['byear'];
		$C_year = $_POST['C_year'];
		$Rship = $_POST['Rship'];

		// Check if user name has been entered
		if (!$_POST['uname']) {
			$errUname = 'Please select a uname';
		}

		// Check if user name is unique
		if ($_POST['uname']) {
			$link2 = pg_Connect("host=localhost dbname=JMN_DEV user=jumbo password=jumbo_pw7");
			$test = pg_query($link2, "SELECT * FROM users WHERE uname = '$uname'");
			$test_name = pg_fetch_result($test, 0, 'uname');
			echo "test_name result: $test_name";
			if ($test_name == $uname) { //pg_query($link2, "SELECT * FROM users WHERE uname = '$uname'")
				$errUname = '' . $uname . ' is not available, please select another.';
			}
			pg_close($link2);
		}

		// !! Need something that'll strip apostrophes or add the \ before them in names !!
		// 		Otherwise it will screw up the entry to the database

		// Check if first name has been entered
		if (!$_POST['fname']) {
			$errFname = 'Please enter your first name';
		}

		// Check if last name has been entered
		if (!$_POST['lname']) {
			$errLname = 'Please enter your last name';
		}
		
		// Check if email has been entered and is valid
		if (!$_POST['email'] || !filter_var($_POST['email'], FILTER_VALIDATE_EMAIL)) {
			$errEmail = 'Please enter a valid email address';
		}

		// Check if email has been entered and is valid
		if (!$_POST['Temail'] || !filter_var($_POST['Temail'], FILTER_VALIDATE_EMAIL) || !strpos($Temail,'tufts.edu')) {
			$errTemail = 'Please enter a valid Tufts email address (Leave blank if not applicable)';
		}
		
		// Check if Rship has been entered and is valid
		if (!$_POST['Rship']) {
			$errRship = 'Please enter a valid affiliation';
		}

		// Necessity of Class year and department are dependent on affiliation
		if ($Rship > 5) {
			// If not a student, staff, or faculty member 
			// Check if dept has been entered and is valid
			if (!$_POST['dept']) {
				$errDEPT = 'Please enter a valid dept';
			}

			// If an undergrad, check for class year
			if ($Rship = 1) {
				// Check if class has been entered and is valid
				if (!$_POST['C_year']) {
					$errclass = 'Please enter a valid class year';
				}
			}
		}

		// Check if byear has been entered and is valid
		if (!$_POST['byear']) {
			$errbyear = 'Please enter a valid birth year';
		}

	// If there are no errors, send the email
	if (!$errUname && !$errFname && !$errLname && !$errEmail && !$errTemail && !$errDEPT && !$errclass && !$errbyear) { 
		$link = pg_Connect("host=localhost dbname=JMN_DEV user=jumbo password=jumbo_pw7");
		pg_exec($link, "INSERT INTO users VALUES (default, '$uname', '{$fname}', '{$lname}', '$email', '$Temail', default, default, default, $dept, $C_year, $byear, default, default, default, $Rship)");
		// Need an error check
		pg_close($link);


		// Should load a new page here confirming that the user's information has been loaded.
		header("Location: confirm.php?name=$fname"); 
	}
}
?>


<!DOCTYPE html>
<html lang="en">
  	<head>
    	<meta charset="utf-8">
    	<meta http-equiv="X-UA-Compatible" content="IE=edge">
    	<meta name="viewport" content="width=device-width, initial-scale=1">
    	<meta name="description" content="Signup form for Jumbo's Maker Network">
    	<meta name="author" content="Brian O'Connell">
    	<title>Jumbo's Maker Network Signup</title>
    	<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
  	</head>
  	<body>
	  	<div class="container">
	  		<div class="row">
	  			<div class="col-md-8 col-md-offset-2">
					<h1 class="page-header text-center">Jumbo's Maker Network Signup</h1>
					<form class="form-horizontal" role="form" method="post" action="SignUp.php">
						
						<!-- User Name Entry -->
						<div class="form-group">
							<label for="uname" class="col-sm-5">Select a User Name</label>
							<div class="col-sm-12">
								<input type="text" class="form-control" id="uname" name="uname" placeholder="User Name" value="<?php echo htmlspecialchars($_POST['uname']); ?>">
								<?php echo "<p class='text-danger'>$errUname</p>";?>
							</div>
						</div>

						<!-- First Name Entry -->
						<div class="form-group">
							<label for="fname" class="col-sm-5">Enter your First Name</label>
							<div class="col-sm-12">
								<input type="text" class="form-control" id="fname" name="fname" placeholder="First Name" value="<?php echo htmlspecialchars($_POST['fname']); ?>">
								<?php echo "<p class='text-danger'>$errFname</p>";?>
							</div>
						</div>

						<!-- Last Name Entry -->
						<div class="form-group">
							<label for="lname" class="col-sm-5">Enter your Last Name</label>
							<div class="col-sm-12">
								<input type="text" class="form-control" id="lname" name="lname" placeholder="Last Name" value="<?php echo htmlspecialchars($_POST['lname']); ?>">
								<?php echo "<p class='text-danger'>$errLname</p>";?>
							</div>
						</div>

						<!-- Tufts Email Address -->
						<div class="form-group">
							<label for="email" class="col-sm-5">Enter your Tufts Email</label>
							<div class="col-sm-12">
								<input type="email" class="form-control" id="Temail" name="Temail" placeholder="exmple@tufts.edu - Leave blank if not applicable" value="<?php echo htmlspecialchars($_POST['Temail']); ?>">
								<?php echo "<p class='text-danger'>$errTemail</p>";?>
							</div>
						</div>

						<!-- Main Email Address -->
						<div class="form-group">
							<label for="email" class="col-sm-5">Enter your Primary Email</label>
							<div class="col-sm-12">
								<input type="email" class="form-control" id="email" name="email" placeholder="example@domain.com" value="<?php echo htmlspecialchars($_POST['email']); ?>">
								<?php echo "<p class='text-danger'>$errEmail</p>";?>
							</div>
						</div>

						<!-- Relationship -->
						<div class="form-group">
							<label class="col-sm-5">Select your Affiliation with Tufts</label>
							<div class="col-sm-12">
								<select name = "Rship" id = "Rship">
									<option value=NULL></option>
									<?php
									foreach($Rships as $row){
									     if($row[rel_id] == $_POST['Rship']){
									          $isSelected = ' selected'; // if the option submited in form is as same as this row we add the selected tag
									     } else {
									          $isSelected = ''; // else we remove any tag
									     }
									     echo "<option value=\"" . $row[rel_id] . "\"" . $isSelected . ">" . $row[rel] . "</option> <br>";
									}
									?>
								</select>
								<div class="select.form-group-sm">
									<?php echo "<p class='text-danger'>$errRship</p>";?>								
								</div>
							</div>
						</div>

						<!-- Class -->
						<div class="form-group">
							<label class="col-sm-5">Select your Class Year</label>
							<div class="col-sm-12">
								<select name = "C_year" id = "C_year">
									<option value=NULL></option>
									<?php
									foreach($Class_YEARS as $row){
									     if($row == $_POST['C_year']){
									          $isSelected = ' selected'; // if the option submited in form is as same as this row we add the selected tag
									     } else {
									          $isSelected = ''; // else we remove any tag
									     }
									     echo "<option value=\"" . $row . "\"" . $isSelected . ">" . $row . "</option> <br>";
									}
									?>
								</select>
								<div class="select.form-group-sm">
									<?php echo "<p class='text-danger'>$errClass</p>";?>								
								</div>
							</div>
						</div>

						<!-- Department -->
 						<div class="form-group">
							<label class="col-sm-5">Select your Department</label>
							<div class="col-sm-12">
								<select name = "dept" id = "dept">
									<option value=NULL></option>
									<?php
									foreach($depts as $row){
									     if($row[deptid] == $_POST['dept']){
									          $isSelected = ' selected'; // if the option submited in form is as same as this row we add the selected tag
									     } else {
									          $isSelected = ''; // else we remove any tag
									     }
									     echo "<option value=\"" . $row[deptid] . "\"" . $isSelected . ">" . $row[dept] . "</option> <br>";
									}
									?>
								</select>
								<div class="select.form-group-sm">
									<?php echo "<p class='text-danger'>$errByear</p>";?>
								</div>
							</div>
						</div>

						<!-- Birth Year for Age -->
						<div class="form-group">
							<label class="col-sm-5">Select your Birth Year</label>
							<div class="col-sm-12">
								<select name = "byear" id = "byear">
									<option value=NULL></option>
									<?php
									foreach($years as $row){
									     if($row == $_POST['byear']){
									          $isSelected = ' selected'; // if the option submited in form is as same as this row we add the selected tag
									     } else {
									          $isSelected = ''; // else we remove any tag
									     }
									     echo "<option value=\"" . $row . "\"" . $isSelected . ">" . $row . "</option> <br>";
									}
									?>
								</select>
								<div class="select.form-group-sm">
									<?php echo "<p class='text-danger'>$errbyear</p>";?>
								</div>
							</div>
						</div>

						<!--  -->

						<!-- <div class="form-group">
							<label class="col-sm-5">Dept</label>
							<div class="col-sm-12">
								<select name = "dept" id = "dept">	
									<option value="Blank1"></option>
								    <option value="Anthropology">Anthropology</option>
								    <option value="Art and Art History">Art and Art History</option>
								    <option value="Biology">Biology</option>
								    <option value="Chemistry">Chemistry</option>
								    <option value="Child Study and Human Development">Child Study and Human Development</option>
								    <option value="Classics">Classics</option>
								    <option value="Computer Science">Computer Science</option>
								    <option value="Drama and Dance">Drama and Dance</option>
								    <option value="Earth and Ocean Sciences">Earth and Ocean Sciences</option>
								    <option value="Economics">Economics</option>
								    <option value="Education">Education</option>
								    <option value="Biomedical Engineering">Biomedical Engineering</option>
								    <option value="Chemical and Biological Engineering ">Chemical and Biological Engineering</option>
								    <option value="Civil and Environmental Engineering">Civil and Environmental Engineering</option>
								    <option value="Education Engineering">Education Engineering</option>
								    <option value="Electrical and Computer Engineering">Electrical and Computer Engineering</option>
								    <option value="Engineering Management">Engineering Management</option>
								    <option value="Mechanical Engineering">Mechanical Engineering</option>
								    <option value="English">English</option>
								    <option value="German, Russian, and Asian Languages/Literature">German, Russian, and Asian Languages/Literature</option>
								    <option value="History">History</option>
								    <option value="Mathematics">Mathematics</option>
								    <option value="Music">Music</option>
								    <option value="Occupational Therapy">Occupational Therapy</option>
								    <option value="Philosophy">Philosophy</option>
								    <option value="Physical Education">Physical Education</option>
								    <option value="Physics and Astronomy">Physics and Astronomy</option>
								    <option value="Political Science">Political Science</option>
								    <option value="Psychology">Psychology</option>
								    <option value="Religion">Religion</option>
								    <option value="Romance Languages">Romance Languages</option>
								    <option value="Sociology">Sociology</option>
								    <option value="Urban and Environmental Policy and Planning">Urban and Environmental Policy and Planning</option>
							    </select>
								<div class="select.form-group-sm">
									<input class="form-control" id="dept" name="dept" option value="<?php echo htmlspecialchars($_POST['dept']); ?>">
			
									<?php echo "<p class='text-danger'>$errDEPT</p>";?>
								
								</div>
							</div>
						</div> -->

<!-- 						<div class="form-group">
							<label class="col-sm-5">Birth Year</label>
							<div class="col-sm-12">
								<select name ="byear" id = "byear">
									<option value="Blank2"></option>
									<option value="2000">2000</option>
								    <option value="1999">1999</option>
								    <option value="1998">1998</option>
								    <option value="1997">1997</option>
								    <option value="1996">1996</option>
								    <option value="1995">1995</option>
								    <option value="1994">1994</option>
								    <option value="1993">1993</option>
								    <option value="1992">1992</option>
								    <option value="1991">1991</option>
								    <option value="1990">1990</option>
								    <option value="1989">1989</option>
								    <option value="1988">1988</option>
								    <option value="1987">1987</option>
								    <option value="1986">1986</option>
								    <option value="1985">1985</option>
								    <option value="1984">1984</option>
								    <option value="1983">1983</option>
								    <option value="1982">1982</option>
								    <option value="1981">1981</option>
								    <option value="1980">1980</option>
								    <option value="1979">1979</option>
								    <option value="1978">1978</option>
								    <option value="1977">1977</option>
								    <option value="1976">1976</option>
								    <option value="1975">1975</option>
								    <option value="1974">1974</option>
								    <option value="1973">1973</option>
								    <option value="1972">1972</option>
								    <option value="1971">1971</option>
								    <option value="1970">1970</option>
								    <option value="1969">1969</option>
								    <option value="1968">1968</option>
								    <option value="1967">1967</option>
								    <option value="1966">1966</option>
								    <option value="1965">1965</option>
								    <option value="1964">1964</option>
								    <option value="1963">1963</option>
								    <option value="1962">1962</option>
								    <option value="1961">1961</option>
								    <option value="1960">1960</option>
								    <option value="1959">1959</option>
								    <option value="1958">1958</option>
								    <option value="1957">1957</option>
								    <option value="1956">1956</option>
								    <option value="1955">1955</option>
								    <option value="1954">1954</option>
								    <option value="1953">1953</option>
								    <option value="1952">1952</option>
								    <option value="1951">1951</option>
								    <option value="1950">1950</option>
								    <option value="Old as Rogers">Too Old (Rogers)</option>
								</select>
								<div class="col-sm-12">
									<input type="byear" class="form-control" id="byear" name="byear" placeholder="1994" value="<?php echo htmlspecialchars($_POST['byear']); ?>">
									<?php echo "<p class='text-danger'>$errbyear</p>";?>
								</div>
							</div>
						</div> -->
<!-- 						<div class="form-group">
							<label class="col-sm-5">class</label>
							<div class="col-sm-12">
								<select name = "class" id = "class">
									<option value="Blank3"></option>
									<option value="2016">2016</option>
								    <option value="2017">2017</option>
								    <option value="2018">2018</option>
								    <option value="2019">2019</option>
								    <option value="Grad">Graduate Student</option>
								    <option value="1952">Post-Graduate Student</option>
								    <option value="1951">Faculty Member</option>
								    <option value="1950">Other</option>
								</select>
								<div class="col-sm-12">
									<?php echo "<p class='text-danger'>$errclass</p>";?>
								</div>
							</div>
						</div> -->

						<!-- Submit button -->
						<div class="form-group">
							<label class="col-sm-5"></label>
							<div class="col-sm-12">
								<input id="submit" name="submit" type="submit" value="Send" class="btn btn-primary">
							</div>
						</div>
						<!-- <div class="form-group">
							<div class="col-sm-12 col-sm-offset-2">
								<?php echo $result; ?>	
							</div>
						</div> -->
					</form> 
				</div>
			</div>
		</div>
  	</body>
</html>