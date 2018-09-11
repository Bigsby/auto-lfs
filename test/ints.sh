    #!/bin/bash
    
    redraw() {
        clear
        echo "Width = $(tput cols) Height = $(tput lines)"
    }

    trap redraw WINCH
    trap "echo 'exiting...'; kill $$" INT
    trap "echo 'terminating...'; exit 23" TERM

    redraw
    while true; do
        :
    done