# Check if .vimrc file already exists
if [ ! -f "$VIMRC_PATH" ]; then
    # Create .vimrc file with desired settings
    echo -e "set number\nsyntax on" > "$VIMRC_PATH"
    
    # Display listening TCP connections
    ss -utplns
    
    echo "Settings applied for the current session."
else
    echo "File $VIMRC_PATH already exists, no changes made."
fi