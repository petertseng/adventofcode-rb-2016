yes=

if [ "$1" = "--yes" ]; then
  yes=1
  shift
fi

day=$1

if [ $# -eq 0 ]; then
  day=$(date --utc +%-d)
  echo "OK, we have to guess the day, let's guess $day???"
else
  shift
  if [ "$1" = "--yes" ]; then
    yes=1
    shift
  fi
fi

daypad=$(seq -f%02g $day $day)

if [ "$yes" = "1" ]; then
  if [ -f input ]; then
    echo "THE INPUT ALREADY EXISTS!!!"
  else
    curl --cookie session=$(cat secrets/session) -o input http://adventofcode.com/2016/day/$day/input
  fi
else
  curl -o input http://example.com
fi

if [ -f $daypad.rb ]; then
  backup="$daypad-$(date +%s).rb"
  echo "I think we should back up $daypad.rb to $backup!"
  mv $daypad.rb $backup
fi

if [ -f TEMPLATE.rb ]; then
  cat TEMPLATE.rb input > $daypad.rb
elif [ -f t.rb ]; then
  cat t.rb input > $daypad.rb
fi
