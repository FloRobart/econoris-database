# Éconoris — Base de données

Ce dépôt contient **tout ce qui concerne la base de données** d'Éconoris :

- les migrations du schéma PostgreSQL, gérées avec [dbmate](https://github.com/amacneil/dbmate) ;
- l'image Docker de migrations `florobart/econoris-migrations` ;
- les fichiers Docker Compose pour lancer la base en développement et en production.

L'API (`econoris-api`) ne contient rien sur la base : elle s'y connecte par un réseau Docker. En production, c'est le réseau interne `econoris-database-net`, déclaré à l'identique dans les deux dépôts ; en développement, c'est `econoris-net`, créé par `docker-compose.dev.yml`.

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

- En production, la base tourne sur l'image durcie `dhi.io/postgres:18` ; en développement, sur l'image officielle `postgres:18`. La version majeure est fixée, car changer de version majeure rend le volume illisible sans migration des données.
- En production, les images de base sont épinglées par digest : mettre à jour Postgres, c'est changer ce digest dans `docker-compose.yml`. Sans cela, aucun correctif de sécurité n'est récupéré.
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

Copier le fichier d'environnement. Les variables de développement y sont commentées car elles ont une valeur par défaut : les décommenter seulement pour les changer (`HOST_UID` et `HOST_GID` : résultats de `id -u` et `id -g`).

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

**Automatiquement (GitHub Actions)** : à chaque merge sur `main`, la CI teste les migrations sur une base vide, puis publie l'image sur Docker Hub et GHCR avec les tags `<version>` et `latest`.

Les secrets `DOCKERHUB_USERNAME` et `DOCKERHUB_TOKEN` doivent être configurés dans le dépôt GitHub.

**À la main** :

```bash
docker build -t florobart/econoris-migrations:1.0.0 -t florobart/econoris-migrations:latest .
```

```bash
docker push --all-tags florobart/econoris-migrations
```

# Déployer en production

En production, `econoris-wrapper` déploie ce dépôt avec le reste de l'écosystème : il crée les secrets, sauvegarde la base, applique les migrations, puis démarre l'API. Voir son README.

Cette section décrit comment lancer ce dépôt seul, depuis le dossier contenant son `docker-compose.yml` et son `.env`.

**Toujours déployer la base avant le serveur.** Le serveur a besoin du schéma à jour.

Prérequis, à préparer une seule fois :

- Le serveur doit être authentifié sur le registre des images durcies :

    ```bash
    docker login dhi.io
    ```

- Les secrets doivent exister dans le dossier `secrets/` (jamais commité) :

    - `secrets/db_password` : le mot de passe de la base, seul dans le fichier ;
    - `secrets/migrations.env` : une seule ligne, avec le mot de passe encodé pour une URL :

        ```
        DATABASE_URL=postgres://<DB_USER>:<DB_PASSWORD>@econoris-database:5432/<DB_NAME>?sslmode=disable
        ```

    Le dossier protège les fichiers sur l'hôte. Les fichiers restent lisibles, car les conteneurs les lisent avec un utilisateur non-root :

    ```bash
    chmod 700 secrets
    ```

    ```bash
    chmod 644 secrets/db_password secrets/migrations.env
    ```

Déploiement :

1. Sauvegarder la base :

    ```bash
    docker compose exec econoris-database pg_dump -U <DB_USER> -d <DB_NAME> > backup_$(date +%F).sql
    ```

2. Récupérer les images. La dernière release est prise par défaut ; pour une autre version, la définir dans `MIGRATIONS_VERSION` :

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

⚠️ Le volume d'une base créée avec l'image officielle `postgres:18` **n'est pas réutilisable** : l'image durcie n'utilise ni le même dossier de données (`18/data` au lieu de `18/docker`) ni le même utilisateur (UID 70 au lieu de 999). Les données passent donc par une sauvegarde et une restauration, dans un nouveau volume.

1. Sauvegarder la base, depuis le dossier de l'ancien `docker-compose.yml` :

    ```bash
    docker compose exec -T <SERVICE_DB> pg_dump -U <DB_USER> -d <DB_NAME> > backup.sql
    ```

2. Vérifier la version de PostgreSQL utilisée. Elle doit être la même que celle de `docker-compose.yml` (PostgreSQL 18) :

    ```sql
    SELECT version();
    ```

3. Indiquer dans `DB_VOLUME_NAME` du `.env` de ce dépôt un nom de volume **différent** de l'ancien. L'ancien volume reste intact et sert de solution de repli.

4. Arrêter l'ancienne stack (sans `-v`, pour **garder** le volume), depuis le dossier de l'ancien `docker-compose.yml` :

    ```bash
    docker compose down
    ```

5. Démarrer uniquement la base avec ce dépôt :

    ```bash
    docker compose up -d econoris-database
    ```

6. Restaurer la sauvegarde :

    ```bash
    docker compose exec -T econoris-database psql -U <DB_USER> -d <DB_NAME> < backup.sql
    ```

7. Marquer la migration de départ comme appliquée :

    ```bash
    docker compose exec econoris-database psql -U <DB_USER> -d <DB_NAME> -c "CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR PRIMARY KEY); INSERT INTO schema_migrations (version) VALUES ('20261025120000');"
    ```

8. Vérifier que dbmate ne voit aucune migration en attente (`Pending: 0`) :

    ```bash
    docker compose run --rm econoris-migrate --no-dump-schema status
    ```

9. Démarrer le reste, puis le serveur :

    ```bash
    docker compose up -d
    ```
