echo "$(LC_ALL=C tr -dc '0-9' < /dev/urandom | fold -w6 | head -1)"
