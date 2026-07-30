#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=============================================="
echo "  Fix Android CI + Gradle Wrapper (Termux)"
echo "=============================================="
echo

if [ ! -d .git ]; then
    echo "[ERROR] Nie jesteś w katalogu repozytorium Git!"
    exit 1
fi

echo "[INFO] Katalog projektu: $(pwd)"

mkdir -p .github/workflows
WORKFLOW=".github/workflows/android.yml"

if [ -f "$WORKFLOW" ]; then
    cp "\( WORKFLOW" " \){WORKFLOW}.bak"
    echo "[INFO] Backup starego workflow → ${WORKFLOW}.bak"
else
    echo "[INFO] Tworzę nowy plik workflow: $WORKFLOW"
fi

cat > "$WORKFLOW" << 'EOF'
name: Android CI

on:
  push:
    branches: [ "main", "master" ]
  pull_request:
    branches: [ "main", "master" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v4
      with:
        lfs: true

    - name: set up JDK 21
      uses: actions/setup-java@v4
      with:
        java-version: '21'
        distribution: 'temurin'
        cache: gradle

    - name: Setup Gradle
      uses: gradle/actions/setup-gradle@v4

    - name: Grant execute permission for gradlew
      run: chmod +x gradlew

    - name: Build with Gradle
      run: ./gradlew assembleDebug --no-daemon

    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: app-debug
        path: app/build/outputs/apk/debug/app-debug.apk
EOF

echo "[INFO] Zaktualizowano $WORKFLOW"

# .gitignore
if [ -f .gitignore ]; then
    sed -i '/gradle-wrapper\.jar/d' .gitignore
fi

if ! grep -q '!gradle/wrapper/gradle-wrapper.jar' .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# Gradle Wrapper - must be committed" >> .gitignore
    echo "!gradle/wrapper/gradle-wrapper.jar" >> .gitignore
    echo "[INFO] Dodano wyjątek dla gradle-wrapper.jar w .gitignore"
fi

# .gitattributes
if [ -f .gitattributes ]; then
    sed -i '/\*\.jar.*lfs/d' .gitattributes
    sed -i '/gradle-wrapper\.jar/d' .gitattributes
    echo "[INFO] Usunięto reguły LFS dla *.jar z .gitattributes"
fi

# Gradle Wrapper
mkdir -p gradle/wrapper
WRAPPER_JAR="gradle/wrapper/gradle-wrapper.jar"
WRAPPER_PROPS="gradle/wrapper/gradle-wrapper.properties"

rm -f "$WRAPPER_JAR"

echo "[INFO] Pobieram czysty gradle-wrapper.jar..."

GRADLE_VERSION="8.10.2"

cat > "$WRAPPER_PROPS" << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

curl -fsSL -o "$WRAPPER_JAR" \
  "https://raw.githubusercontent.com/gradle/gradle/v${GRADLE_VERSION}/gradle/wrapper/gradle-wrapper.jar"

SIZE=$(stat -c%s "$WRAPPER_JAR" 2>/dev/null || echo 0)

if [ "$SIZE" -lt 10000 ]; then
    echo "[ERROR] Nie udało się pobrać prawidłowego gradle-wrapper.jar (rozmiar: $SIZE)"
    exit 1
fi

echo "[INFO] gradle-wrapper.jar pobrany poprawnie (rozmiar: ${SIZE} bajtów)"

if [ -f gradlew ]; then
    chmod +x gradlew
    echo "[INFO] Ustawiono +x na gradlew"
fi

echo "[INFO] Dodaję pliki do Gita..."

git add -f "$WRAPPER_JAR"
git add "$WRAPPER_PROPS"
git add "$WORKFLOW"
git add .gitignore 2>/dev/null || true
git add .gitattributes 2>/dev/null || true
git add gradlew gradlew.bat 2>/dev/null || true

if git diff --cached --quiet; then
    echo "[WARN] Brak nowych zmian do commitowania."
else
    git commit -m "fix: regenerate gradle-wrapper.jar + update Android CI workflow"
    echo "[INFO] Commit utworzony."
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo
echo "=============================================="
echo "  Gotowe lokalnie!"
echo "=============================================="
echo
echo "Teraz wypchnij zmiany:"
echo
echo "  git push origin $BRANCH"
echo
