#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

#TRUNCATE=$($PSQL "TRUNCATE TABLE games;")

SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))
echo $SECRET_NUMBER
NUMBER_OF_TRIES=0

echo "Enter your username:"
read INPUT_USERNAME

USERNAME_RESULT=$($PSQL "SELECT username FROM games WHERE username='$INPUT_USERNAME';")

if [[ -z $USERNAME_RESULT ]]
then
  INSERT_USERNAME=$($PSQL "INSERT INTO games(username, games_played, best_game) VALUES('$INPUT_USERNAME', 1, 0);")
  echo -e "\nWelcome, $INPUT_USERNAME! It looks like this is your first time here."
else
  echo "$($PSQL "SELECT username, games_played, best_game FROM games WHERE username='$INPUT_USERNAME';")" | while IFS="|" read USERNAME GAMES_PLAYED BEST_GAME
  do
    echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done

  UPDATE_GP=$($PSQL "UPDATE games SET games_played=(( $($PSQL "SELECT games_played FROM games WHERE username='$INPUT_USERNAME'") + 1 )) WHERE username='$INPUT_USERNAME';")
fi

GUESS_FUNCTION() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  else
    echo -e "\nGuess the secret number between 1 and 1000:"
  fi
  read INPUT_NUMBER

  if [[ $INPUT_NUMBER =~ ^[0-9]+$ ]]
  then
    (( NUMBER_OF_TRIES++ ))
    
    if [[ $INPUT_NUMBER -gt $SECRET_NUMBER ]]
    then
      GUESS_FUNCTION "It's lower than that, guess again:"
    elif [[ $INPUT_NUMBER -lt $SECRET_NUMBER ]]
    then
      GUESS_FUNCTION "It's higher than that, guess again:"
    else
      echo -e "\nYou guessed it in $NUMBER_OF_TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"

      BEST_GAME_RESULT=$($PSQL "SELECT best_game FROM games WHERE username='$INPUT_USERNAME';")
      if [[ $BEST_GAME_RESULT == 0 ]]
      then
        UPDATE_BG=$($PSQL "UPDATE games SET best_game=$NUMBER_OF_TRIES WHERE username='$INPUT_USERNAME';")
      elif [[ $NUMBER_OF_TRIES < $BEST_GAME_RESULT ]]
      then
        UPDATE_BG=$($PSQL "UPDATE games SET best_game=$NUMBER_OF_TRIES WHERE username='$INPUT_USERNAME';")
      fi
    fi
  else
    GUESS_FUNCTION "That is not an integer, guess again:"
  fi
}

GUESS_FUNCTION
