#!/bin/bash

# GitHub feltöltési script
# Ez a script létrehozza a GitHub repository-t és feltölti a ZIP fájlt

# Színek beállítása
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}GitHub repository feltöltési segéd${NC}"
echo "-----------------------------------------"

# Felhasználónév bekérése
read -p "Kérem adja meg a GitHub felhasználónevét: " username

# Repository név bekérése
read -p "Kérem adja meg a repository nevét (pl. milesszakaja): " repo_name

# Leírás bekérése
read -p "Kérem adja meg a repository rövid leírását: " description

# Token bekérése
read -p "Kérem adja meg a GitHub Personal Access Tokent: " token

# Repository publikus vagy privát
read -p "Publikus repository legyen? (igen/nem): " is_public
if [[ "$is_public" == "igen" ]]; then
  visibility="public"
else
  visibility="private"
fi

echo -e "${YELLOW}Repository létrehozása...${NC}"

# Repository létrehozása
response=$(curl -s -X POST \
  -H "Authorization: token $token" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos \
  -d "{\"name\":\"$repo_name\",\"description\":\"$description\",\"private\":$([ "$visibility" == "private" ] && echo "true" || echo "false")}")

# Ellenőrizzük, hogy sikerült-e a létrehozás
if echo "$response" | grep -q "id"; then
  echo -e "${GREEN}Repository sikeresen létrehozva!${NC}"
  repo_url="https://github.com/$username/$repo_name"
  echo "Repository URL: $repo_url"
else
  echo -e "${RED}Hiba történt a repository létrehozásakor:${NC}"
  echo "$response"
  exit 1
fi

echo -e "${YELLOW}ZIP fájl feltöltése...${NC}"

# Hozzunk létre egy ideiglenes git repository-t a feltöltéshez
echo "Ideiglenes Git repository létrehozása..."
mkdir -p temp_repo
cd temp_repo
git init

# Másoljuk át a ZIP fájlt
cp ../milesszakaja_projekt.zip .

# Commit és push
git config --local user.email "user@example.com"
git config --local user.name "$username"
git remote add origin "https://$token@github.com/$username/$repo_name.git"
git add milesszakaja_projekt.zip
git commit -m "Első feltöltés: projekt ZIP fájl"

# Push
push_result=$(git push -u origin master 2>&1)
if echo "$push_result" | grep -q "fatal\|error"; then
  echo -e "${RED}Hiba történt a feltöltés során:${NC}"
  echo "$push_result"
  
  # Próbáljuk újra main ággal
  echo -e "${YELLOW}Újrapróbálkozás 'main' ággal...${NC}"
  git branch -m master main
  push_result=$(git push -u origin main 2>&1)
  
  if echo "$push_result" | grep -q "fatal\|error"; then
    echo -e "${RED}A feltöltés nem sikerült:${NC}"
    echo "$push_result"
    exit 1
  else
    echo -e "${GREEN}Sikeres feltöltés 'main' ágra!${NC}"
  fi
else
  echo -e "${GREEN}Sikeres feltöltés 'master' ágra!${NC}"
fi

# Takarítás
cd ..
rm -rf temp_repo

echo -e "${GREEN}A ZIP fájl sikeresen feltöltve a GitHub repository-ba:${NC}"
echo "$repo_url"
echo -e "${YELLOW}Megjegyzés: Győződjön meg róla, hogy látja a ZIP fájlt a repository-ban.${NC}"
echo -e "${YELLOW}Ha szeretné, letöltheti, majd kicsomagolhatja a projektet a GitHub-ról.${NC}"