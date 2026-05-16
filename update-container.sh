#!/bin/bash

# Farben
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Keine Farbe

# Basisverzeichnis für Docker-Stacks
BASE_DIR="$HOME/docker"

# Header
echo -e "${RED}==============================${NC}"
echo -e "   Docker Container Updater"
echo -e "${RED}==============================${NC}"
echo


# Überprüfen auf vorhandene Container
mapfile -t CONTAINERS < <(docker ps -a --format "{{.Names}}")
if [ ${#CONTAINERS[@]} -eq 0 ]; then
        echo "Keine Container gefunden."
        exit 0
fi

# Container auflisten
echo -e "${CYAN}Verfügbare Container:${NC}"
echo " 0) [Mehrere Container auswählen]"
for i in "${!CONTAINERS[@]}"; do

    # Containername abrufen
    CONTAINER="${CONTAINERS[$i]}"
    printf " %d) %s " $((i+1)) "${CONTAINER}"
	echo

done

# Benutzereingabe
echo
echo -ne "${CYAN}Geben Sie die Nummern der Container ein, die Sie aktualisieren möchten (z.B. 1 3 5): ${NC}"
read -r -a SELECTION
SELECTED_CONTAINERS=()



## Validierung
for SEL in "${MULTI_SELECTIONS[@]}"; do
    # Überprüfen, ob Eingabe eine Zahl ist
    if ! [[ "$SEL" =~ ^[0-9]+$ ]]; then
        echo "Ungültige Eingabe: $SEL. Überspringe."
        continue
    fi

    # Überprüfen, ob Zahl im gültigen Bereich ist
    if [ "$SEL" -gt "${#CONTAINERS[@]}" ]; then
        echo "Nummer $SEL existiert nicht. Überspringe."
        continue
    fi

    # Wenn Eingabe 0 ist, alle Container auswählen
    if [ "$SEL" -eq 0 ]; then
        SELECTED_CONTAINERS=("${CONTAINERS[@]}")
        break
    fi
    
    INDEX=$((SEL-1))
    SELECTED_CONTAINERS+=("${CONTAINERS[$INDEX]}")
done


# Auswahl auflösen
echo
echo -e "${CYAN}Ausgewählt:${NC}"
for c in "${SELECTED_CONTAINERS[@]}"; do
        echo " - $c"
done

echo
echo -e "${CYAN}Zugehörige Images:${NC}"
for c in "${SELECTED_CONTAINERS[@]}"; do
        IMAGE=$(docker inspect --format='{{.Config.Image}}' "$c")
        echo " - $c → $IMAGE"
done


# Images pullen
echo
echo -e "${CYAN}Pulling images...${NC}"

for c in "${SELECTED_CONTAINERS[@]}"; do
    PROJECT=$(docker inspect "$c" --format '{{ index .Config.Labels "com.docker.compose.project" }}')
    STACK_DIR="$BASE_DIR/$PROJECT"

    if [ ! -f "$STACK_DIR/docker-compose.yml" ]; then
        echo " - $c: kein docker-compose.yml gefunden, übersprungen."
        continue
    fi

    echo " - $c: docker compose pull"
    docker compose -f "$STACK_DIR/docker-compose.yml" pull

    echo " - $c: docker compose up -d"
    docker compose -f "$STACK_DIR/docker-compose.yml" up -d --no-build
done
