function otw
    set line "psw$argv[1]: $argv[2]"
    if not grep -q "^psw$argv[1]:" ~/dev/otw-bandit.txt
        echo $line >> ~/dev/otw-bandit.txt
        echo "Added: $line"
    else
        echo "Entry for psw$argv[1] already exists:"
        grep "^psw$argv[1]:" ~/dev/otw-bandit.txt
    end
    cat ~/dev/otw-bandit.txt
end
