<html> 
 <body>

<br><br><br><br><br><br>
<form action="generate_objection.php" method="get">
Objection : <input type="text" name="s" size=100/> <input type="submit" />
</form>

<?php 

function strToHex($string)
{
    $hex='';
    for ($i=0; $i < strlen($string); $i++)
    {
        $hex .= dechex(ord($string[$i]));
    }
    return $hex;
}

if (isset($_GET["s"]))
{ 
 echo 
 "
  <br><br><br>
  Your objection is ready<br>
 ";
 echo "<a href=\"objection.php?s=".strToHex($_GET["s"])."\">".$_GET["s"]."</a><br>";

} ?>
<br>

 </body>

</html>
