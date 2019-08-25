#!/bin/bash
. theme.conf
code=""
rgb=""
invalid_entry=0

#Limit RGB channel to 0-255
function cap_rgb {
  cap=${1%.*}
  if [ $cap -gt 255 ]; then
    cap=255
  fi
  if [ $cap -lt 1 ]; then
    cap=0
  fi
  echo $cap
}

#Convert hex to decimal for calculations.
function hex2rgb {
  code=$1
  a=0
  for i in $(echo $code | grep -o ..); do
    a=$(($a+1))
    rgb[$a]=$(echo "ibase=16;obase=A; $i" | bc)
  done
}

#Convert rgb dec to hex
function rgb2hex {
code=$(cap_rgb $1)
code="$(echo "ibase=10;obase=16; $code" | bc)"
if [ $(echo $code | wc -c ) -lt 3 ]; then
  code=0$code
fi
if [ $(echo $code | grep -c "-") -gt 0 ]; then
  echo "("$code")"echo "ibase=16;obase=A; $i" | bc
else
  echo $code
fi
}

# Overdrive RGB Channels
function overdrive {
  hex2rgb "$2"
  a=0
  for i in $(echo ${rgb[*]}); do
    a=$(($a+1))
    rgb_boost[$a]=$(echo "$(echo "$1" | gawk -F, '{ print $'$a' }' )*255" | bc)
    rgb[$a]=$(echo "${rgb[$a]%.*}+${rgb_boost[$a]%.*}" | bc)
    output=$output$(rgb2hex ${rgb[$a]})
  done
  echo $output
}

#Desaturize colors
function saturation {
  hex2rgb "$2"
  diviser="$1"
  #Calc average rgb brightness
  a=0
  for i in $(echo ${rgb[*]}); do
    a=$(($a+1))
    avgN=$(($avgN+${rgb[$a]}))
  done
  avgN=$(echo "$avgN / $a" | bc)
  if [ $sat -gt 10 ]; then
    avgN=0
  else
    avgN=$(echo "$avgN * $(echo "1 - $diviser" | bc)" | bc)
  fi

  #Populate RGB values with average value
  a=0
  for i in $(echo ${rgb[*]}); do
    a=$(($a+1))
    color=$(echo "$avgN + $(echo "${rgb[$a]} * $diviser" | bc)" | bc)
    output=$output$(rgb2hex $color)
  done
  echo $output
}

function verify {
  if [ $(echo $1 | grep -ci ",") -lt 1 ] && [ $(echo $1 | grep -ci "#") -lt 1 ]; then
    echo "INVALID"
    exit
  fi
  if [ $(echo $1 | grep -ci "#") -gt 0 ]; then
    #Filter out invalid hex codes and change 3 digit codes to 6 digit codes
  verified="$(echo $1 | grep -io [a-f0-9] | grep -io [a-f0-9] | awk '{ print; count++; if (count==6) exit }' | tr -d "\n")"
  a=0
  code=$verified
  if [ $(echo $code | wc -c ) -lt 5 ]; then
    verified=""
    for i in $(echo $code | grep -o .); do
      a=$(($a+1))
      i=$i$i
      verified=$verified$i
    done
  fi

  #Apply case filter to output. The bc command is case sensative for hex values.
  verified=$(echo $verified | grep -o [A-Fa-f0-9].*)
  verified="${verified^^}"
else
  if [ $(echo $1 | grep -ci ",") -gt 0 ]; then
    rgb[1]=$(echo $1 | gawk -F, '{ print $1 }')
    rgb[2]=$(echo $1 | gawk -F, '{ print $2 }')
    rgb[3]=$(echo $1 | gawk -F, '{ print $3 }')
    a=0
    for i in $(echo ${rgb[*]}); do
      a=$(($a+1))
      verified=$verified$(rgb2hex ${rgb[$a]})
    done
      verified="${verified^^}"
    fi
fi

  #Convert saturation level to integer
  sat=$(echo "$saturation_level * 10" | bc)
  sat=${sat%.*}

  #Determine color algorithm to use
  if [ $(echo "$enable_overdrive" | grep -ci "true") -lt 1 ] && [ $sat = 10 ]; then
            echo $verified
  else
    if [ $(echo "$enable_overdrive" | grep -ci "true") -gt 0 ] && [ $sat != 10 ]; then
      saturation "$saturation_level" $(overdrive "$window_R,$window_G,$window_B" "$verified")
    else
      if [ $sat != 10 ]; then
        saturation "$saturation_level" "$verified"
      fi
      if [ $enable_overdrive = "true" ]; then
        overdrive "$window_R,$window_G,$window_B" "$verified"
      fi
    fi
  fi
}

#Calculate shadow and highlight colors then convert decimal back to hex
function calc_colors {
a=0
#Calc boost color
boost[1]=$(echo "255*$hl_R" | bc) #Red
boost[2]=$(echo "255*$hl_G" | bc) #Green
boost[3]=$(echo "255*$hl_B" | bc) #Blue
boost1[1]=$(echo "255*$s_R" | bc) #Red
boost1[2]=$(echo "255*$s_G" | bc) #Green
boost1[3]=$(echo "255*$s_B" | bc) #Blue
for i in $(echo ${rgb[*]}); do
  a=$(($a+1))
  #Calculated shadow, highlight and disabled colors
  shadow[$a]=$(echo "${rgb[$a]}*$shadow_multiplier" | bc)
  highlight[$a]=$(echo "${rgb[$a]}*$highlight_multiplier" | bc)
  if [ $(echo $high_contrast | grep -ic "true") -gt 0 ]; then
    disabled[$a]=$(echo "${fgcolor_rgb[$a]}*$disabled_fg_multiplier" | bc)
  else
    disabled[$a]=$(echo "${rgb[$a]}*$disabled_fg_multiplier" | bc)
  fi
  #Color boost
  shadow[$a]=$(echo "$(cap_rgb ${shadow[$a]%.*})+${boost1[$a]%.*}" | bc)
  highlight[$a]=$(echo "$(cap_rgb ${highlight[$a]%.*})+${boost[$a]%.*}" | bc)

  #Cap at 255 and ignore negative values
  highlight[$a]=$(cap_rgb ${highlight[$a]%.*})
  shadow[$a]=$(cap_rgb ${shadow[$a]%.*})
  disabled[$a]=$(cap_rgb ${disabled[$a]%.*})

  #Convert DEC to HEX
  shadow_hex=$shadow_hex$(rgb2hex ${shadow[$a]%.*})
  highlight_hex=$highlight_hex$(rgb2hex ${highlight[$a]%.*})
  disabled_hex=$disabled_hex$(rgb2hex ${disabled[$a]%.*})
done

highlight="$highlight_hex"
shadow="$shadow_hex"
disabled_fgcolor="$disabled_hex"
}

function compile_assets {
cd images
for i in $(ls -d */ | grep -o .*[A-Za-z0-9]); do
cd $i
if [ $(pwd | grep -ci "ins") -gt 0 ]; then
  convert *base.png -fuzz 15% -fill "#$bgcolor" -opaque "#ff00fa" base.png
else
  convert *base.png -fuzz 15% -fill "#$basecolor" -opaque "#ff00fa" base.png
fi
convert *border.png -fuzz 15% -fill "#$border" -opaque "#ff00fa" border.png
convert *shadow.png -fuzz 15% -fill "#$shadow" -opaque "#ff00fa" shadow.png
convert *highlight.png -fuzz 15% -fill "#$highlight" -opaque "#ff00fa" highlight.png
convert *background.png -fuzz 15% -fill "#$bgcolor" -opaque "#ff00fa" background.png
convert *check.png -fuzz 15% -fill "#$basefg" -opaque "#ff00fa" check.png
convert *_aa.png -fuzz 15% -fill "#$bgcolor" -opaque "#ff00fa" aa.png
convert *_text.png -fuzz 15% -fill "#$fgcolor" -opaque "#ff00fa" text.png
convert *_text_disabled.png -fuzz 15% -fill "#$disabled_fgcolor" -opaque "#ff00fa" text_disabled.png
convert -background none -page +0+0 background.png -page +0+0 highlight.png \
-page +0+0 shadow.png -page 0+0 border.png -page +0+0 base.png -page +0+0 check.png \
-page +0+0 aa.png -page +0+0 text.png -page +0+0 text_disabled.png -layers flatten $i.png
#remove work files
mv $i.png ../assets/
rm shadow.png border.png highlight.png background.png base.png check.png aa.png
#return to directory
cd ../
done
cd assets

#compile arrows
mv arrow.png arrow_up.png
convert -rotate "90" arrow_up.png arrow_right.png
convert -rotate "90" arrow_right.png arrow_down.png
convert -rotate "90" arrow_down.png arrow_left.png
for i in $(ls arrow*.png); do
  convert "$i" -fuzz 15% -fill "#$disabled_fgcolor" -opaque "$fgcolor" ${i%.*}"_ins.png"
done

#compile all scrollbar buttons
convert -page +0+0 scrollbar_button.png -page +0+0 arrow_up.png -layers flatten scroll_up_button.png
convert -page +0+0 scrollbar_button.png -page +0+0 arrow_right.png -layers flatten scroll_right_button.png
convert -page +0+0 scrollbar_button.png -page +0+0 arrow_down.png -layers flatten scroll_down_button.png
convert -page +0+0 scrollbar_button.png -page +0+0 arrow_left.png -layers flatten scroll_left_button.png
convert -page +0+0 scrollbar_button_active.png -page +0+0 arrow_up.png -layers flatten scroll_up_button_active.png
convert -page +0+0 scrollbar_button_active.png -page +0+0 arrow_right.png -layers flatten scroll_right_button_active.png
convert -page +0+0 scrollbar_button_active.png -page +0+0 arrow_down.png -layers flatten scroll_down_button_active.png
convert -page +0+0 scrollbar_button_active.png -page +0+0 arrow_left.png -layers flatten scroll_left_button_active.png

#compile tabs
convert -flip tab.png tab_left.png
convert -flip tab_checked.png tab_left_checked.png
convert -flip tab_gap.png tab_gap_left.png
convert -rotate "90" tab_left.png tab_left.png
convert -rotate "90" tab_left_checked.png tab_left_checked.png
convert -rotate "90" tab_gap_left.png tab_gap_left.png
cp tab_gap_left.png tab_gap_right.png
convert -flip tab_bottom.png tab_right.png
convert -flip tab_bottom_checked.png tab_right_checked.png
convert -rotate "90" tab_right.png tab_right.png
convert -rotate "90" tab_right_checked.png tab_right_checked.png
mv tab.png tab_top.png
mv tab_checked.png tab_top_checked.png
cp tab_gap.png tab_gap_top.png
mv tab_gap.png tab_gap_bottom.png

#compile switch button
convert -background none -page +0+0 switch_button.png -page +0+0 switch_off.png -layers flatten switch.png
convert -background none -page +0+0 switch_button_ins.png -page +0+0 switch_off.png -layers flatten switch_ins.png
convert -background none -page +0+0 switch_button.png -page +0+0 switch_on.png -layers flatten switch_checked.png
convert -background none -page +0+0 switch_button_ins.png -page +0+0 switch_on.png -layers flatten switch_ins_checked.png
rm switch_off.png switch_on.png switch_button.png switch_button_ins.png
cd ..

cp progressbar/*.png assets/
cp assets/progressbar_horiz.png assets/menuitem.png
cp null/null_image.png assets/null.png
#colorize extra widgets
convert assets/menuitem.png -fuzz 15% -fill "#$selectedbg" -opaque "#ff00fa" assets/menuitem.png
convert assets/progressbar_horiz.png -fuzz 15% -fill "#$selectedbg" -opaque "#ff00fa" assets/progressbar_horiz.png
convert assets/progressbar_vert.png -fuzz 15% -fill "#$selectedbg" -opaque "#ff00fa" assets/progressbar_vert.png

#compile whisker menu side image
convert -size 27x800 canvas:"#$activetitle1" assets/side_canvas.png
#magick -size 27x400 gradient:"#0803ee"-"#$border" assets/side_gradient.png
magick -size 27x400 gradient:"#$activetitle"-"#$activetitle1" assets/side_gradient.png
convert -background none -page +0+0 assets/side_canvas.png -page 0+0 assets/side_gradient.png -layers flatten assets/menu_side_gradient.png
convert -rotate -90 assets/menu_side_gradient.png assets/menu_side_gradient.png
convert -font helvetica-bold -fill "#$activetitletext" -pointsize $menu_side_text_size -draw "text $menu_side_text_offset '$menu_side_text'" assets/menu_side_gradient.png assets/menu_side.png
convert -rotate -90 assets/menu_side.png assets/menu_side.png

rm assets/menu_side_gradient.png

cd assets
#gtk3 assets
gtk3="../../gtk-3.0/assets/"
cp tab*.png $gtk3
cp menu_side.png $gtk3
cp menubar.png $gtk3/toolbar.png
cp scrollbar_trough.png $gtk3
cp radio*.png $gtk3
cp c_box*.png $gtk3
cp arrow*.png $gtk3
cp switch*.png $gtk3
cp comboboxbutton.png $gtk3/combobox.png
cp comboboxbutton_ins.png $gtk3/combobox_disabled.png
cp comboboxbutton_checked.png $gtk3/combobox_checked.png
cp scrollbar_button.png $gtk3
rm scrollbar_button.png
cp scroll_*_button.png $gtk3
mv headerbox.png $gtk3
cp warning.png $gtk3
mv caja_menu_side.png $gtk3
#metacity-1 assets
mv close_normal.png ../../metacity-1/
mv close_normal_small.png ../../metacity-1/
mv close_pressed.png ../../metacity-1/
mv close_pressed_small.png ../../metacity-1/
mv maximize_normal.png ../../metacity-1/
mv maximize_pressed.png ../../metacity-1/
mv minimize_normal.png ../../metacity-1/
mv minimize_pressed.png ../../metacity-1/
mv restore_normal.png ../../metacity-1/
mv restore_pressed.png ../../metacity-1/
#gtk2 assets
mv *.png ../../gtk-2.0/assets/
cd ../../
}

function build_theme_config
{
echo "Generating rc and css config files..."

#Theme index
sed -i 's/Redmond97/Redmond97 '"$Theme_name"'/g' index.theme

#GTK-2.0
sed -i 's/fg_color:#000/fg_color:'#$fgcolor'/g' base.rc
sed -i 's/bg_color:#c0c0c0/bg_color:'#$bgcolor'/g' base.rc
sed -i 's/base_color:#fff/base_color:'#$basecolor'/g' base.rc
sed -i 's/text_color:#000/text_color:'#$basefg'/g' base.rc
sed -i 's/selected_bg_color:#0000aa/selected_bg_color:'#$selectedbg'/g' base.rc
sed -i 's/selected_fg_color:#fff/selected_fg_color:'#$selectedtext'/g' base.rc
sed -i 's/disabled_fg_color:#e0e0e0/disabled_fg_color:'#$disabled_fgcolor'/g' base.rc

#GTK-3.0
sed -i 's/@define-color fg_color #000000/@define-color fg_color '#$fgcolor'/g' gtk-base.css
sed -i 's/@define-color bg_color #c0c0c0/@define-color bg_color '#$bgcolor'/g' gtk-base.css
sed -i 's/@define-color base_color #FFFFFF/@define-color base_color '#$basecolor'/g' gtk-base.css
sed -i 's/@define-color text_color #000000/@define-color text_color '#$basefg'/g' gtk-base.css
sed -i 's/@define-color selected_bg_color #0000aa/@define-color selected_bg_color '#$selectedbg'/g' gtk-base.css
sed -i 's/@define-color selected_fg_color #FFFFFF/@define-color selected_fg_color '#$selectedtext'/g' gtk-base.css
sed -i 's/@define-color light_shadow #FFFFFF/@define-color light_shadow '#$highlight'/g' gtk-base.css
sed -i 's/@define-color disabled_fg_color #EFEFEF/@define-color disabled_fg_color '#$disabled_fgcolor'/g' gtk-base.css
sed -i 's/@define-color borders #000/@define-color borders '#$border'/g' gtk-base.css
sed -i 's/@define-color dark_shadow shade(@bg_color, 0.7)/@define-color dark_shadow '#$shadow'/g' gtk-base.css
sed -i 's/@define-color active_title_color @selected_bg_color/@define-color active_title_color #'$activetitle'/g' gtk-base.css
sed -i 's/@define-color active_title_color1 @selected_bg_color/@define-color active_title_color1 #'$activetitle1'/g' gtk-base.css
sed -i 's/@define-color active_title_text @selected_fg_color/@define-color active_title_text #'$activetitletext'/g' gtk-base.css

if [ $(echo "$enable_alternate_menu" | grep -ci "true") -lt 1 ]; then
  sed -i 's/border-left: 23px solid/border-left: '"$menu_side_width"'px solid/g' "gtk-3.0/whisker-menu.css"
fi
if [ $(echo "$enable_alternate_menu" | grep -ci "true") -gt 0 ]; then
  sed -i 's/whisker-menu.css/whisker-menu2.css/g' "gtk.css"
fi

#XFCE4WM
sed -i 's/active_text_color=#FFFFFF/active_text_color='#$activetitletext'/g' themerc
sed -i 's/inactive_text_color=#c0c0c0/inactive_text_color='#$inactivetitletext'/g' themerc
sed -i 's/active_color_1=#6f99be/active_color_1='#$activetitle'/g' themerc
sed -i 's/inactive_color_1=#7d7a73/inactive_color_1='#$inactivetitle'/g' themerc
sed -i 's/active_border_color=#000000/active_border_color='#$border'/g' themerc
sed -i 's/inactive_border_color=#000000/inactive_border_color='#$border'/g' themerc
if [ $(echo "$high_contrast" | grep -ci "true") -gt 0 ]; then
  echo "active_border_color=#$border" >> themerc
  echo "inactive_border_color=#$border" >> themerc
  echo "active_hilight_2=#$border" >> themerc
  echo "inactive_hilight_2=#$border" >> themerc
fi

#metacity-1
sed -i 's/_activegradient1_/#'$activetitle1'/g' metacity-theme-1.xml
sed -i 's/_activegradient2_/#'$activetitle'/g' metacity-theme-1.xml
sed -i 's/_inactivegradient1_/#'$inactivetitle'/g' metacity-theme-1.xml
sed -i 's/_inactivegradient2_/#'$inactivetitle1'/g' metacity-theme-1.xml
sed -i 's/Redmond2K/Redmond97 '"$Theme_name"'/g' metacity-theme-1.xml
sed -i 's/line color=\"#ffffff\"/line color=\"#'$highlight'\"/g' metacity-theme-1.xml 
sed -i 's/title x=\"3\" y=\"2\" color="gtk:bg\[NORMAL\]\"/title x=\"3\" y=\"2\" color=\"#'$inactivetitletext'\"/g' metacity-theme-1.xml
sed -i 's/title x=\"3\" y=\"2\" color=\"#ffffff\"/title x=\"3\" y=\"2\" color=\"#'$activetitletext'\"/g' metacity-theme-1.xml
sed -i 's/404040/'$border'/g' metacity-theme-1.xml
sed -i 's/808080/'$shadow'/g' metacity-theme-1.xml
sed -i 's/404040/'$border'/g' metacity-theme-1.xml
sed -i 's/404040/'$border'/g' metacity-theme-1.xml
sed -i 's/color=\"gtk:bg\[NORMAL\]\"/color=\"#'$bgcolor'\"/g' metacity-theme-1.xml


#Append changes
cat gtkrc >> base.rc
rm -rf gtkrc
mv base.rc gtk-2.0/gtkrc
cat gtk.css >> gtk-base.css
rm gtk.css
mv gtk-base.css gtk-3.0/gtk.css
mv themerc xfwm4/
mv metacity-theme-1.xml metacity-1/
}

function prompt {
if [ "$invalid_entry" = "1" ]; then
  echo "Warning: invalid color code entered or config file is corrupt. Exiting..."
  exit 1
fi
echo $invalid_entry
echo "Theme name: $Theme_name"
echo "Selected colors:"
hex2rgb $bgcolor
echo "Window BG color: #$bgcolor, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $fgcolor
echo "Window FG color: #$fgcolor, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $basecolor
echo "Base BG color: #$basecolor, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $basefg
echo "Base text color: #$basefg, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $selectedbg
echo "Selected BG color: #$selectedbg, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $selectedtext
echo "Selected FG color: #$selectedtext, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $activetitle
echo "Active titlebar color: #$activetitle, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $activetitletext
echo "Active title text: #$activetitletext, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $inactivetitle
echo "Inactive titlebar color: #$inactivetitle, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $inactivetitletext
echo "Inactive title text: #$inactivetitletext, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $border
echo "Border color: #$border, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
echo ""
echo "3D highlight color boost: #$(rgb2hex ${boost[1]})$(rgb2hex ${boost[2]})$(rgb2hex ${boost[3]}), RGB: ${boost[1]%.*},${boost[2]%.*},${boost[3]%.*}"
echo "3D shadow color boost: #$(rgb2hex ${boost1[1]})$(rgb2hex ${boost1[2]})$(rgb2hex ${boost1[3]}), RGB: ${boost1[1]%.*},${boost1[2]%.*},${boost1[3]%.*}"
echo ""
echo "Calculated colors:"
hex2rgb $highlight
echo "Highlight color: #$highlight, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $shadow
echo "Shadow color: #$shadow, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
hex2rgb $disabled_fgcolor
echo "Disabled FG color: #$disabled_fgcolor, RGB: ${rgb[1]%.*},${rgb[2]%.*},${rgb[3]%.*}"
echo "Press enter to continue or ctrl+c to cancel..."
#read $entry
build
}

function build {
echo "Cleaning any previous orphaned files..."
#Clean incomplete or interupted builds, compile images
cleanup  2>>/dev/null
echo "Extracting base files..."
tar -xzf base.tar.gz 2>>/dev/null
echo "Compiling theme images..."
compile_assets $2 2>>/dev/null
build_theme_config

theme_name="Redmond97 $Theme_name"
rm -rf ~/.themes/"$theme_name"
mkdir ~/.themes/"$theme_name"
mv gtk-2.0 ~/.themes/"$theme_name"/
mv gtk-3.0 ~/.themes/"$theme_name"/
mv xfwm4 ~/.themes/"$theme_name"/
mv metacity-1 ~/.themes/"$theme_name"/
cp theme.conf ~/.themes/"$theme_name"/
mv version ~/.themes/"$theme_name"/
cp LICENSE ~/.themes/"$theme_name"/
mv index.theme ~/.themes/"$theme_name"/
echo "GTK2, GTK3 and XFWM4 themes configured and installed."
echo "Theme '$theme_name' installed in ~/.themes/$theme_name. You may now select and use your theme."
}

function cleanup {
#Clean incomplete or interupted builds, compile images
rm -rf gtk-2.0 gtk-3.0 images xfwm4
rm rm base.rc gtk.css gtk-base.css gtkrc themerc version
}

#Verify config file hex codes
echo "Verifying and calculating colors. Please wait..."
fgcolor=$(verify $fgcolor)
bgcolor=$(verify $bgcolor)
basecolor=$(verify $basecolor)
basefg=$(verify $basefg)
selectedbg=$(verify $selectedbg)
selectedtext=$(verify $selectedtext)
activetitletext=$(verify $activetitletext)
inactivetitletext=$(verify $inactivetitletext)
activetitle=$(verify $activetitle)
inactivetitle=$(verify $inactivetitle)
border=$(verify $border)
if [ -z "$activetitle1" ]; then
  activetitle1="$border"
else
  activetitle1=$(verify $activetitle1)
fi
if [ -z "$inactivetitle1" ]; then
  inactivetitle1="$bgcolor"
else
  inactivetitle1=$(verify $inactivetitle1)
fi

#Convert to rgb for calculations
hex2rgb $fgcolor
fgcolor_rgb[1]=${rgb[1]%.*}
fgcolor_rgb[2]=${rgb[2]%.*}
fgcolor_rgb[3]=${rgb[3]%.*}

#main functions
hex2rgb "$bgcolor"
calc_colors
prompt
cleanup  2>>/dev/null
