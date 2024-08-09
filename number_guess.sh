#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
MAX_SECRET_NUMBER=1000
SECRET_NUMBER=$((1 + $RANDOM % $MAX_SECRET_NUMBER))

echo -e "Enter your username:\n"

read USERNAME

function GREAT_NEW_USER {
  echo -e "\nWelcome, $1! It looks like this is your first time here.\n"
}

function READ_USER {

  USER_QUERY_RESULT=$($PSQL "SELECT games_played, best_game_tries FROM users LEFT JOIN user_statistics USING(user_id) WHERE name='$1'")

  if [[ -z $USER_QUERY_RESULT ]]
  then
    GREAT_NEW_USER $1
  else
    echo -e "$USER_QUERY_RESULT" | while IFS="|" read GAMES_PLAYED BEST_GAME_TRIES
    do
      if [[ -z $BEST_GAME_TRIES ]]
      then
        GREAT_NEW_USER $1
      else
        echo -e "\nWelcome back, $1! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME_TRIES guesses.\n"
      fi
    done
  fi
}

function CREATE_NEW_USER {
  USER_INSERTION_RESULT=$($PSQL "INSERT INTO users(name) VALUES ('$1')")
}

function FINISH_GAME {
  USER_ID_QERY_RESULT=$($PSQL "SELECT user_id FROM users WHERE name='$USERNAME'")

  if [[ -z $USER_ID_QERY_RESULT ]]
  then
    CREATE_NEW_USER $USERNAME
    USER_ID_QERY_RESULT=$($PSQL "SELECT user_id FROM users WHERE name='$USERNAME'")
  fi

  USER_STATISTIC_QUERY_RESULT=$($PSQL "SELECT games_played, best_game_tries FROM user_statistics WHERE user_id='$USER_ID_QERY_RESULT'")

  if [[ -z $USER_STATISTIC_QUERY_RESULT ]]
  then
    NEW_USER_STATISTIC_INSERTION_RESULT=$($PSQL "INSERT INTO user_statistics(user_id, games_played, best_game_tries) VALUES($USER_ID_QERY_RESULT, 1, $1)")
  else
    echo -e "$USER_STATISTIC_QUERY_RESULT" | while IFS="|" read GAMES_PLAYED BEST_GAME_TRIES
    do
      NEW_GAMES_PLAYED=$(($GAMES_PLAYED + 1))
      
      if [[ BEST_GAME_TRIES -gt $1 ]]
      then
        NEW_BEST_GAME_TRIES=$1
      else
        NEW_BEST_GAME_TRIES=$BEST_GAME_TRIES
      fi

      USER_STATISTIC_UPDATION_RESULT=$($PSQL "UPDATE user_statistics SET games_played=$NEW_GAMES_PLAYED, best_game_tries=$NEW_BEST_GAME_TRIES WHERE user_id=$USER_ID_QERY_RESULT")
    done
  fi
  echo -e "You guessed it in $1 tries. The secret number was $SECRET_NUMBER. Nice job!"
}

function MAKE_GUESS {
  local NUMBER_OF_TRIES=$2

  if [[ -z $1 ]]
  then
    echo -e "Guess the secret number between 1 and $MAX_SECRET_NUMBER:\n"
  else
    if [[ ! $1 =~ ^[0-9]+$ ]]
    then
      echo -e "That is not an integer, guess again:\n"
    else
      if [[ $1 -gt $SECRET_NUMBER ]]
      then
        echo -e "It's lower than that, guess again:\n"
      fi

      if [[ $1 -lt $SECRET_NUMBER ]]
      then
        echo -e "It's higher than that, guess again:\n"
      fi
    fi
  fi

  if [[ $1 -eq $SECRET_NUMBER ]]
  then
    FINISH_GAME $NUMBER_OF_TRIES
  else
    read GUESS

    if [[ -z $NUMBER_OF_TRIES ]]
    then
      NUMBER_OF_TRIES=1
    else
      NUMBER_OF_TRIES=$(($NUMBER_OF_TRIES + 1))
    fi

    MAKE_GUESS $GUESS $NUMBER_OF_TRIES
  fi
}

READ_USER $USERNAME

MAKE_GUESS
