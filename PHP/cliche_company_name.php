<html>
 <head><title>Clich&eacute; IT Company Name Generator</title>
<style type="text/css">
A:link {text-decoration: none; color: black;}
A:visited {text-decoration: none; color: gray;}
A:active {text-decoration: none; color: black;}
A:hover {text-decoration: underline; color: red;}
</style>
 </head>
 <body>
  <center><br><br><br><br>
  <h2>Clich&eacute; (Lame) IT Company Name Generator</h2><br>
  -----------------------------------------<br>
  <h3>
   <?php
      $last_line = system('./generateName.sh', $retval); 
      $line_array = explode ( ' ', $last_line );
      echo "<br>OR<br>".$line_array[1]." ".$line_array[0];
     // $line_array = str_split ( $last_line , 2 );
     // echo "<br>OR<br>".$line_array[1]." ".$line_array[0];
   ?>
    </h3> 
    -----------------------------------------<br>
    <a href="javascript:location.reload(true)">Generate A New One..</a> <br>
    -----------------------------------------<br> <br>
   <br><br>
    <a href="http://ammar.gr/">Back to ammar.gr</a>
   </center>
 </body>
</html>
