# Éconoris — Base de données

Ce dépôt contient **tout ce qui concerne la base de données** d'Éconoris :

- les migrations du schéma PostgreSQL, gérées avec [dbmate](https://github.com/amacneil/dbmate) ;
- l'image Docker de migrations `florobart/econoris-migrations` ;
- les fichiers Docker Compose pour lancer la base en développement et en production.

Le serveur (`Econoris_server`) ne contient rien sur la base. Il se connecte simplement au réseau Docker `econoris-net` créé par ce dépôt.

# Table des matières

- [Structure](#structure)
- [Principe](#principe)
- [Règles à respecter](#règles-à-respecter)
- [Développement](#développement)
- [Créer une migration](#créer-une-migration)
- [Publier l'image de migrations](#publier-limage-de-migrations)
- [Déployer en production](#déployer-en-production)
- [En cas de problème](#en-cas-de-problème)
- [Basculer une base existante](#basculer-une-base-existante)

# Structure

```
econoris-database/
├── db/
│   ├── migrations/          ← une migration = un fichier, horodaté, immuable
│   └── schema.sql           ← état complet de la base, généré par dbmate (ne pas modifier à la main)
├── .github/workflows/       ← test des migrations + publication de l'image
├── Dockerfile               ← image de migrations (dbmate + db/migrations)
├── docker-compose.yml       ← production : postgres + migrations
├── docker-compose.dev.yml   ← développement : postgres + dbmate
└── .env.example
```

# Principe

- La base tourne sur l'image **officielle** `postgres:18`. La version majeure est fixée, car changer de version majeure rend le volume illisible sans migration des données.
- Chaque changement de schéma est un **fichier de migration** dans `db/migrations/`. Il contient une section `up` (appliquer) et une section `down` (annuler).
- dbmate enregistre les migrations appliquées dans la table `schema_migrations`. `dbmate up` n'exécute **que** celles qui manquent, dans l'ordre de leur horodatage.
- Chaque migration est exécutée dans une transaction : si elle échoue, rien n'est appliqué.

# Règles à respecter

- **Ne jamais modifier une migration déjà appliquée en production.** Pour corriger, on crée une nouvelle migration.
- **Ne jamais modifier le schéma de production à la main** (psql, DBeaver...). Tout passe par une migration.
- **Une migration = un changement logique**, petit et facile à relire.
- **Toujours écrire la section `down`** et la tester en local.
- **Changements destructifs en deux temps** (supprimer ou renommer une colonne utilisée par le serveur) :
  1. déployer un serveur qui n'utilise plus la colonne ;
  2. déployer ensuite la migration qui la supprime.
- **Pas de données de test dans les migrations.** Seules les données de référence indispensables au fonctionnement y ont leur place.
- **Faire une sauvegarde avant chaque déploiement** en production.

# Développement

Copier le fichier d'environnement et l'adapter (`HOST_UID` et `HOST_GID` : résultats de `id -u` et `id -g`) :

```bash
cp .env.example .env
```

Démarrer la base et appliquer toutes les migrations :

```bash
docker compose -f docker-compose.dev.yml up -d
```

`econoris-migrate` applique les migrations, régénère `db/schema.sql`, puis s'arrête. La base reste accessible sur `127.0.0.1:${DB_PORT}`, et le serveur en développement la joint via le réseau `econoris-net`.

Commandes dbmate utiles (aucune installation nécessaire, tout passe par Docker) :

```bash
docker compose -f docker-compose.dev.yml run --rm econoris-migrate status
```

```bash
docker compose -f docker-compose.dev.yml run --rm econoris-migrate up
```

```bash
docker compose -f docker-compose.dev.yml run --rm econoris-migrate rollback
```

- `status` : liste les migrations appliquées et en attente.
- `up` : applique les migrations en attente et régénère `db/schema.sql`.
- `rollback` : annule la dernière migration appliquée (section `down`).

Repartir d'une base vide (⚠️ supprime les données de développement) :

```bash
docker compose -f docker-compose.dev.yml down -v
```

# Créer une migration

1. Générer le fichier (le nom décrit le changement, en anglais, en snake_case) :

    ```bash
    docker compose -f docker-compose.dev.yml run --rm econoris-migrate new add_note_to_loans
    ```

    dbmate crée `db/migrations/<horodatage>_add_note_to_loans.sql`.

2. Remplir les deux sections :

    ```sql
    -- migrate:up
    ALTER TABLE loans ADD COLUMN note TEXT;

    -- migrate:down
    ALTER TABLE loans DROP COLUMN note;
    ```

3. Tester : `up`, puis `rollback`, puis `up` (voir [Développement](#développement)).
4. Adapter le serveur si nécessaire (repositories, schémas zod...).
5. Commiter la migration **et** `db/schema.sql`. Le diff de `schema.sql` montre l'effet réel du changement.

Pour modifier une fonction ou un trigger, créer une nouvelle migration avec `CREATE OR REPLACE FUNCTION ...` dans `up`, et l'ancienne définition dans `down`.

# Publier l'image de migrations

L'image `florobart/econoris-migrations` contient dbmate et toutes les migrations. Au démarrage, elle applique les migrations en attente, puis s'arrête.

**Automatiquement (GitHub Actions)** : pousser un tag de version. Le workflow teste les migrations sur une base vide, puis publie l'image sur Docker Hub et GHCR avec les tags `<version>` et `latest`.

```bash
git tag v1.0.0
```

```bash
git push origin v1.0.0
```

Les secrets `DOCKERHUB_USERNAME` et `DOCKERHUB_TOKEN` doivent être configurés dans le dépôt GitHub.

**À la main** :

```bash
docker build -t florobart/econoris-migrations:1.0.0 -t florobart/econoris-migrations:latest .
```

```bash
docker push --all-tags florobart/econoris-migrations
```

# Déployer en production

Sur le serveur, dans le dossier contenant le `docker-compose.yml` et le `.env` de ce dépôt.

**Toujours déployer la base avant le serveur.** Le serveur a besoin du réseau `econoris-net` et du schéma à jour.

1. Sauvegarder la base :

    ```bash
    docker compose exec econoris-db pg_dump -U <DB_USER> -d <DB_NAME> > backup_$(date +%F).sql
    ```

2. Indiquer la version à déployer dans `.env` (`MIGRATIONS_VERSION=1.0.0`), puis récupérer les images :

    ```bash
    docker compose pull
    ```

3. Démarrer. La base démarre, puis `econoris-migrate` applique **uniquement** les migrations manquantes et s'arrête :

    ```bash
    docker compose up -d
    ```

4. Vérifier que les migrations sont passées (le service doit être `Exited (0)`) :

    ```bash
    docker compose ps -a
    ```

    ```bash
    docker compose logs econoris-migrate
    ```

5. Déployer ensuite le serveur, depuis son propre dossier.

S'il n'y a aucune migration en attente, `econoris-migrate` ne fait rien. On peut relancer `docker compose up -d` autant de fois que nécessaire.

# En cas de problème

- **La migration échoue** : elle est annulée (transaction), la base reste dans son état précédent et `econoris-migrate` se termine en erreur (`Exited (1)`). Ne pas déployer le nouveau serveur. Corriger avec une nouvelle migration, publier une nouvelle image, redéployer.
- **La migration passe mais elle est fausse** : écrire une nouvelle migration corrective. En dernier recours, restaurer la sauvegarde.
- **Le `rollback` est réservé au développement.** En production, on corrige vers l'avant.

# Basculer une base existante

À faire **une seule fois**, sur une base créée avec l'ancien système (scripts dans `docker-entrypoint-initdb.d`). Les tables existent déjà, donc la migration `20261025120000_baseline` ne doit **pas** être exécutée. Il faut la marquer comme appliquée.

1. Sauvegarder la base (voir [Déployer en production](#déployer-en-production)).

2. Vérifier la version de PostgreSQL utilisée. Elle doit être la même que celle de `docker-compose.yml` (`postgres:18`) :

    ```sql
    SELECT version();
    ```

3. Récupérer le nom du volume de données actuel et le mettre dans `DB_VOLUME_NAME` du `.env` de ce dépôt. Sinon, une nouvelle base vide est créée :

    ```bash
    docker volume ls
    ```

4. Arrêter l'ancienne stack (sans `-v`, pour **garder** le volume), depuis le dossier de l'ancien `docker-compose.yml` :

    ```bash
    docker compose down
    ```

5. Démarrer uniquement la base avec ce dépôt :

    ```bash
    docker compose up -d econoris-db
    ```

6. Marquer la migration de départ comme appliquée :

    ```bash
    docker compose exec econoris-db psql -U <DB_USER> -d <DB_NAME> -c "CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR PRIMARY KEY); INSERT INTO schema_migrations (version) VALUES ('20261025120000');"
    ```

7. Vérifier que dbmate ne voit aucune migration en attente (`Pending: 0`) :

    ```bash
    docker compose run --rm econoris-migrate --no-dump-schema status
    ```

8. Démarrer le reste, puis le serveur :

    ```bash
    docker compose up -d
    ```
