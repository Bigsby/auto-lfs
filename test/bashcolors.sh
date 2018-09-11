#!/bin/bash

echo "16 colors"     
#Background
for clbg in {40..47} {100..107} 49 ; do
    #Foreground
    for clfg in {30..37} {90..97} 39 ; do
        #Formatting
        for attr in 0 1 2 4 5 7 ; do
            #Print the result
            echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
        done
        echo #Newline
    done
done
    
echo "256 colors"
for fgbg in 38 48 ; do # Foreground / Background
    for color in {0..255} ; do # Colors
        # Display the color
        printf "\e[${fgbg};5;%sm  %3s  \e[0m" $color $color
        # Display 6 colors per lines
        if [ $((($color + 1) % 6)) == 4 ] ; then
            echo # New line
        fi
    done
    echo # New line
done


C_R="\e[0m"
C_BOLD="\e[1m"
C_BOLD_R="\e[21m" # Doesn't work
C_DIM="\e[2m"
C_DIM_R="\e[22m"
C_ITALIC="\e[3m"
C_ITALIC_R="\e[23m"
C_UNDERLINE="\e[4m"
C_UNDERLINE_R="\e[24m"
C_BLINK="\e[5m"
C_BLINK_R="\e[25m"
C_REVERSE="\e[7m"
C_REVERSE_R="\e[27m"
C_HIDDEN="\e[8m"
C_HIDDEN_R="\e[28m"
C_STRIKE="\e[9m"
C_STRIKE_R="\e[29m"



echo -e "this is $C_BOLD""bold$C_R or not"
echo -e "this is $C_DIM""dim$C_DIM_R or not"
echo -e "this is $C_ITALIC""italic$C_ITALIC_R or not"
echo -e "this is $C_UNDERLINE""underlined$C_UNDERLINE_R or not"
echo -e "this is $C_BLINK""blinking$C_BLINK_R or not"
echo -e "this is $C_REVERSE""reversed$C_REVERSE_R or not"
echo -e "this is $C_HIDDEN""hidden$C_HIDDEN_R or not"
echo -e "this is $C_STRIKE""strike-through$C_STRIKE_R or not"

echo -en "$C_R"