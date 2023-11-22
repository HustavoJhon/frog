# Setup colors
$magenta = [console]::ForegroundColor = "Magenta"
$green = [console]::ForegroundColor = "Green"
$white = [console]::ForegroundColor = "White"
$blue = [console]::ForegroundColor = "Blue"
$red = [console]::ForegroundColor = "Red"
$black = [console]::BackgroundColor = "Black"
$yellow = [console]::ForegroundColor = "Yellow"
$cyan = [console]::ForegroundColor = "Cyan"
$reset = [console]::ResetColor()
$bgyellow = [console]::BackgroundColor = "Yellow"
$bgwhite = [console]::BackgroundColor = "White"


# ================================================================================

Clear-Host # clear screen

Write-Output "   ${c7}󰌠 ${c7}         ${c4}󰏘 ${c4}    ${c3}${c6}󰮯 |"
Write-Output "${c3}   _        @..@    ${c3}${c5}󰊠 |"
Write-Output "${c3} ('v')     (----)   ${c3}${c4}󰊠 |$(Get-De-Wm)"
Write-Output "${c3}//-=-\\   ( >__< )  ${c3}${c7}󰊠 |${($env:SHELL -split '/')[1]}"
Write-Output "${c3}(\_=_/)   ^^ ~~ ^^  ${c3}${c1}󰊠 |${env:USERNAME}${c5}"
