<HTML>
<HEAD>
<TITLE>Objection!</TITLE>
</HEAD>
<BODY bgcolor="#ffffff"><center>
<!--Originaly found at -> objection@mrdictionary.net -->
<OBJECT classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width=100% height=100%
codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=5,0,0,0">

<?php 
function hexToStr($hex)
{
    $string='';
    for ($i=0; $i < strlen($hex)-1; $i+=2)
    {
        $string .= chr(hexdec($hex[$i].$hex[$i+1]));
    }
    return $string;
}
?>




<PARAM NAME=movie VALUE=<?php echo "\"objection.swf?s=".hexToStr($_GET["s"])."\""; ?> >
<PARAM NAME=loop VALUE=false>
<PARAM NAME=menu VALUE=false>
<PARAM NAME=quality VALUE=high>
<PARAM NAME=bgcolor VALUE=#FFFFFF>
<PARAM NAME=width VALUE=100%>
<PARAM NAME=height VALUE=100%>
<EMBED src=<?php echo "\"objection.swf?s=".hexToStr($_GET["s"])."\""; ?> 
loop=false menu=false quality=high bgcolor=#FFFFFF TYPE="application/x-shockwave-flash"
width=100% height=100% PLUGINSPAGE="http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash"></EMBED>
</OBJECT>    </center>  

</BODY>
</HTML>
