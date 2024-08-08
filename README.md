
Pour tester les paramètres du CLI, créer un Scheme avec un script de post post-actions pour Build, comme ceci :

```
Pour avoir les variables d'environnement, sélectionner Provide build settings from "webclients"
echo SCHEME webclients-cli: post actions de BUILD
date > /tmp/scheme.txt
set > /tmp/scheme-env.txt
mkdir -p "$PROJECT_DIR/bin"
rm -f "$PROJECT_DIR/bin/$EXECUTABLE_NAME"
cp "$TARGET_BUILD_DIR/$EXECUTABLE_NAME" "$PROJECT_DIR/bin"
```

