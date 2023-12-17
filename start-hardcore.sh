echo "Starting service..."

# Minecraft server container name
CONTAINER_NAME="hardcore-mc"

docker-compose up -d

echo "Waiting for service to start..."

while true; do
    if docker logs $CONTAINER_NAME | grep -q "RCON running on"; then
        echo "World ready!"
        break
    fi
    sleep 1
done

echo "Setting up world constriants..."

random_x=$(( $(shuf -i 0-1000000 -n 1) - 500000 ))
random_z=$(( $(shuf -i 0-1000000 -n 1) - 500000 ))

docker exec $CONTAINER_NAME rcon-cli "gamerule announceAdvancements false"
docker exec $CONTAINER_NAME rcon-cli "setworldspawn $random_x 0 $random_z"
docker exec $CONTAINER_NAME rcon-cli "worldborder center $random_x $random_z"
docker exec $CONTAINER_NAME rcon-cli "worldborder set 501"
docker exec $CONTAINER_NAME rcon-cli "gamerule spawnRadius 99999"

echo "Done! You can now connect to the server."

# Function to add a player to a team
make_hardcore_team() {
    player_name="$1"
    team_name="team_$player_name"
    docker exec $CONTAINER_NAME rcon-cli "team add $team_name"
    docker exec $CONTAINER_NAME rcon-cli "team modify $team_name friendlyFire true"
    docker exec $CONTAINER_NAME rcon-cli "team modify $team_name nametagVisibility never"
    docker exec "$CONTAINER_NAME" rcon-cli "team join $team_name $player_name"
}

# Follow the container logs
docker logs -f "$CONTAINER_NAME" | while read -r line; do
  # Check if the line indicates that a player has joined
  if echo "$line" | grep -q "joined the game"; then
    # Extract the player's name and add them to the team
    player_name=$(echo "$line" | awk '{print $4}' | tr -d '[]')
    make_hardcore_team "$player_name"
  fi
done
