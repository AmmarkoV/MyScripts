#!/bin/bash
 
for i in $@; do  

AVXINSTR=`objdump -d $i | grep  'vbroadcastss\|vbroadcastsd\|vbroadcastf128\|vinsertf128\|vextractf128\|vmaskmovps\|vmaskmovpd\|vpermilps\|vpermilpd\|vperm2f128\|vzeroall\|vzeroupper'`


if [ -z "$AVXINSTR" ] 
then 
 echo "File is clean of AVX instructions" > /dev/null     
else
 echo "File $i has AVX instructions"
fi

SSEINSTR=`objdump -d $i | grep  'movss\|movaps\|movups\|movlps\|movhps\|movlhps\|movhlps\|addss\|subss\|mulss\|divss\|rcpss\|sqrtss\|maxss\|minss\|rsqrtss\|addps\|subps\|mulps\|divps\|rcpps\|sqrtps\|maxps\|minps\|rsqrtps\|cmpss\|comiss\|ucomiss\|cmpps\|shufps\|unpckhps\|unpcklps\|cvtsi2ss\|cvtss2si\|cvttss2si\|cvtpi2ps\|cvtps2pi\|cvttps2pi\|andps\|orps\|xorps\|andnps\|pmulhuw\|psadbw\|pavgb\|pavgw\|pmaxub\|pminub\|pmaxsw\|pminsw\|pextrw\|pinsrw\|pmovmskb\|pshufw\|mxcsr\|ldmxcsr\|stmxcsr\|movntq\|movntps\|maskmovq\|prefetch0\|prefetch1\|prefetch2\|prefetchnta\|sfence'`

if [ -z "$SSEINSTR" ] 
then 
 echo "File is clean of SSE instructions" > /dev/null     
else
 echo "File $i has SSE instructions"
fi
 
done 
  

exit 0
