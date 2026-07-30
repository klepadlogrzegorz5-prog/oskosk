#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[INFO] Start od punktu 3..."

# 3. Utwórz folder wrapper
mkdir -p gradle/wrapper
echo "[INFO] Folder gradle/wrapper gotowy"

# 4. Pobierz czysty gradle-wrapper.jar
echo "[INFO] Pobieram gradle-wrapper.jar..."
curl -fsSL -o gradle/wrapper/gradle-wrapper.jar \
  "https://raw.githubusercontent.com/gradle/gradle/v8.10.2/gradle/wrapper/gradle-wrapper.jar"

# 5. Sprawdź rozmiar
SIZE=$(stat -c%s gradle/wrapper/gradle-wrapper.jar 2>/dev/null || echo 0)
echo "[INFO] Rozmiar pliku: $SIZE bajtów"

if [ "$SIZE" -lt 10000 ]; then
    echo "[ERROR] Plik jest za mały – pobieranie się nie udało!"
    exit 1
fi
echo "[INFO] gradle-wrapper.jar pobrany poprawnie"

# 6. Nadpisz gradle-wrapper.properties
cat > gradle/wrapper/gradle-wrapper.properties << 'PROPS'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.10.2-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROPS
echo "[INFO] gradle-wrapper.properties zaktualizowany"

# 7. Uprawnienia gradlew
if [ -f gradlew ]; then
    chmod +x gradlew
    echo "[INFO] Ustawiono +x na gradlew"
fi

# 8. Napraw .gitignore
echo "" >> .gitignore
echo "# Gradle Wrapper - must be committed" >> .gitignore
echo "!gradle/wrapper/gradle-wrapper.jar" >> .gitignore
echo "[INFO] Dodano wyjątek w .gitignore"

# 9. Usuń reguły LFS z .gitattributes
if [ -f .gitattributes ]; then
    sed -i '/\*\.jar.*lfs/d' .gitattributes
    sed -i '/gradle-wrapper\.jar/d' .gitattributes
    echo "[INFO] Usunięto reguły LFS z .gitattributes"
fi

echo
echo "=============================================="
echo "  Gotowe!"
echo "=============================================="
echo
echo "Teraz ręcznie wklej android.yml:"
echo "  nano .github/workflows/android.yml"
echo
echo "Potem wykonaj:"
echo "  git add -f gradle/wrapper/gradle-wrapper.jar"
echo "  git add gradle/wrapper/gradle-wrapper.properties"
echo "  git add .github/workflows/android.yml"
echo "  git add .gitignore"
echo "  git add gradlew"
echo "  git commit -m \"fix: regenerate gradle-wrapper.jar + update Android CI workflow\""
echo "  git push origin main"
echo
