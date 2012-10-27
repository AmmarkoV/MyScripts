<?php
function using_ie()
{
    $u_agent = $_SERVER['HTTP_USER_AGENT'];
    $ub = False;
    if(preg_match('/MSIE/i',$u_agent))
    {
        $ub = True;
    }
   
    return $ub;
}
 
    if ((using_ie())) //
    {
        ?>
        <div class="iebox" width=150 align="center"> 
             <a href="http://www.mozilla.org/en-US/firefox/new/"><img src="firefox.gif" width=150 border=0 alt="Get Firefox"></a>  
              <font color="red">Internet Explorer Detected</font><br>
             <a href="http://www.mozilla.org/en-US/firefox/new/">Mozilla Firefox is way better!!!!</a>           
        </div>
        <?php
    } else
    {
        ?>
        <div class="happybox" width=150 align="center"> 
             <img src="happy.gif" width=150 border=0 ><br>
             Thank you for not using Internet Explorer          
        </div>
        <?php       	
    } 	
?>