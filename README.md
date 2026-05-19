# Wild Alterations

## Français

Wild Alterations est un plugin PSDK qui permet de rendre les rencontres sauvages plus variées en donnant une chance aux Pokémon sauvages de commencer le combat avec une altération de statut ou avec des PV déjà manquants.

### Fonctionnalités

- Chance configurable d'appliquer une altération à chaque Pokémon sauvage.
- Deux types d'altérations possibles :
  - altération de statut ;
  - perte de PV selon une plage configurable.
- Répartition configurable entre les altérations de statut et les pertes de PV grâce à un système de poids.
- Liste configurable des statuts disponibles et de leur poids.
- Exclusion automatique, par défaut, des combats forcés, roaming et des Pokémon boss du plugin [CC - Pokémon Boss System](https://discord.com/channels/143824995867557888/1273021231561572363).
- Options dédiées pour inclure ou exclure les combats de pêche et Safari.
- Exclusion configurable d'espèces précises via leur `db_symbol`.
- Exclusion configurable de maps précises via leur `map_id`.
- Logs optionnels en console via `log_info`.

### Installation

1. Téléchargez le fichier `.psdkplug` du plugin.
2. Placez le fichier `.psdkplug` dans le dossier `scripts/` de votre projet PSDK.
3. Démarrez le jeu : le Plugin Manager installera alors le plugin automatiquement.
4. Le fichier de configuration est disponible ici :

```text
Data/configs/plugins/wild_alterations_config.json
```

Après modification de la configuration, redémarrez le jeu pour être sûr que les changements soient pris en compte.

### Configuration

Exemple de configuration :

```json
{
  "enabled": true,
  "logs": false,
  "alterationChance": 15,
  "alterationTypes": [
    { "name": "status", "weight": 20 },
    { "name": "hp", "weight": 80 }
  ],
  "status": [
    { "name": "poison", "weight": 40 },
    { "name": "paralysis", "weight": 40 },
    { "name": "sleep", "weight": 20 }
  ],
  "hp": {
    "lossPercentRange": [5, 10]
  },
  "applyTo": {
    "forcedBattles": false,
    "boss": false,
    "roaming": false,
    "fishing": true,
    "safari": true
  },
  "exclude": {
    "species": [":mewtwo", ":pikachu"],
    "maps": [3, 12, 42]
  }
}
```

#### Options générales

| Clé | Type | Description |
| --- | --- | --- |
| `enabled` | booléen | Active ou désactive entièrement le plugin. |
| `logs` | booléen | Active les logs console. Les logs utilisent `log_info`. |
| `alterationChance` | nombre | Pourcentage de chance qu'un Pokémon sauvage reçoive une altération. La valeur est limitée entre `0` et `100`. |

#### Types d'altérations

`alterationTypes` définit le poids de chaque type d'altération.

```json
"alterationTypes": [
  { "name": "status", "weight": 20 },
  { "name": "hp", "weight": 80 }
]
```

Les poids ne sont pas obligés de faire `100`. Le plugin utilise leur proportion. Par exemple, `20 / 80` donne le même résultat que `1 / 4`.

Types disponibles :

| Nom | Effet |
| --- | --- |
| `status` | Tente d'appliquer une altération de statut. |
| `hp` | Retire un pourcentage des PV max du Pokémon. |

Si le type choisi échoue, le plugin tente l'autre type en fallback. Par exemple, si un statut ne peut pas être appliqué, le plugin tente une perte de PV.

#### Statuts

`status` définit les statuts possibles et leur poids.

```json
"status": [
  { "name": "poison", "weight": 40 },
  { "name": "paralysis", "weight": 40 },
  { "name": "sleep", "weight": 20 }
]
```

Statuts disponibles :

| Nom | Statut |
| --- | --- |
| `poison` | Poison |
| `toxic` | Poison grave |
| `paralysis` | Paralysie |
| `burn` | Brûlure |
| `sleep` | Sommeil |
| `freeze` | Gel |

Un statut avec un poids inférieur ou égal à `0` est ignoré. Si un Pokémon ne peut pas recevoir le statut tiré, le plugin tente un autre statut disponible.

#### PV

`hp.lossPercentRange` définit la plage de pourcentage de PV max à retirer.

```json
"hp": {
  "lossPercentRange": [5, 10]
}
```

Avec `[5, 10]`, le Pokémon perdra entre `5%` et `10%` de ses PV max. Si la valeur atteint `100` ou plus, le plugin garde toujours au moins `1 PV`.

#### Cibles

`applyTo` permet de choisir les types de combats sauvages concernés.

```json
"applyTo": {
  "forcedBattles": false,
  "boss": false,
  "roaming": false,
  "fishing": true,
  "safari": true
}
```

| Clé | Description |
| --- | --- |
| `forcedBattles` | Applique le plugin aux combats sauvages forcés par événement. |
| `boss` | Applique le plugin aux Pokémon marqués comme boss par [CC - Pokémon Boss System](https://discord.com/channels/143824995867557888/1273021231561572363). |
| `roaming` | Applique le plugin aux Pokémon roaming. |
| `fishing` | Applique le plugin aux rencontres obtenues à la pêche. |
| `safari` | Applique le plugin aux rencontres Safari. |

#### Exclusions

`exclude` permet d'empêcher le plugin de s'appliquer à certaines espèces ou certaines maps.

```json
"exclude": {
  "species": [":mewtwo", ":pikachu"],
  "maps": [3, 12, 42]
}
```

| Clé | Description |
| --- | --- |
| `species` | Liste de `db_symbol` d'espèces à ignorer. Les valeurs doivent être écrites sous forme de chaînes JSON, par exemple `":mewtwo"`. |
| `maps` | Liste de `map_id` sur lesquelles le plugin ne s'applique pas. |

Une espèce exclue est simplement ignorée dans le combat. Une map exclue bloque le plugin pour toute la rencontre sauvage.

JSON ne permet pas d'écrire directement des symboles Ruby non quotés comme `:mewtwo`. Il faut donc les écrire comme des chaînes, par exemple `":mewtwo"` ; le plugin les convertit ensuite en `:mewtwo` en interne. La forme `"mewtwo"` est aussi acceptée.

## English

Wild Alterations is a PSDK plugin that makes wild encounters more varied by giving wild Pokémon a chance to start battle with a status condition or with some HP already missing.

### Features

- Configurable chance to apply an alteration to each wild Pokémon.
- Two possible alteration types:
  - status condition;
  - HP loss within a configurable range.
- Configurable weighting between status conditions and HP loss.
- Configurable status list and status weights.
- Forced battles, roaming Pokémon and boss Pokémon from [CC - Pokémon Boss System](https://discord.com/channels/143824995867557888/1273021231561572363) are ignored by default.
- Dedicated options to include or exclude fishing and Safari encounters.
- Configurable species exclusions using `db_symbol`.
- Configurable map exclusions using `map_id`.
- Optional console logs through `log_info`.

### Installation

1. Download the plugin `.psdkplug` file.
2. Put the `.psdkplug` file in your project's `scripts/` folder.
3. Start the game: the Plugin Manager will then install the plugin automatically.
4. The configuration file is available here:

```text
Data/configs/plugins/wild_alterations_config.json
```

After editing the configuration, restart the game to make sure the changes are loaded.

### Configuration

Configuration example:

```json
{
  "enabled": true,
  "logs": false,
  "alterationChance": 15,
  "alterationTypes": [
    { "name": "status", "weight": 20 },
    { "name": "hp", "weight": 80 }
  ],
  "status": [
    { "name": "poison", "weight": 40 },
    { "name": "paralysis", "weight": 40 },
    { "name": "sleep", "weight": 20 }
  ],
  "hp": {
    "lossPercentRange": [5, 10]
  },
  "applyTo": {
    "forcedBattles": false,
    "boss": false,
    "roaming": false,
    "fishing": true,
    "safari": true
  },
  "exclude": {
    "species": [":mewtwo", ":pikachu"],
    "maps": [3, 12, 42]
  }
}
```

#### General Options

| Key | Type | Description |
| --- | --- | --- |
| `enabled` | boolean | Enables or disables the plugin entirely. |
| `logs` | boolean | Enables console logs. Logs use `log_info`. |
| `alterationChance` | number | Chance, in percent, for a wild Pokémon to receive an alteration. The value is clamped between `0` and `100`. |

#### Alteration Types

`alterationTypes` defines the weight of each alteration type.

```json
"alterationTypes": [
  { "name": "status", "weight": 20 },
  { "name": "hp", "weight": 80 }
]
```

Weights do not need to add up to `100`. The plugin uses their proportion. For example, `20 / 80` gives the same result as `1 / 4`.

Available types:

| Name | Effect |
| --- | --- |
| `status` | Tries to apply a status condition. |
| `hp` | Removes a percentage of the Pokémon's max HP. |

If the selected type fails, the plugin tries the other type as a fallback. For example, if a status cannot be applied, the plugin tries HP loss.

#### Status Conditions

`status` defines the possible status conditions and their weights.

```json
"status": [
  { "name": "poison", "weight": 40 },
  { "name": "paralysis", "weight": 40 },
  { "name": "sleep", "weight": 20 }
]
```

Available status names:

| Name | Status |
| --- | --- |
| `poison` | Poison |
| `toxic` | Bad poison |
| `paralysis` | Paralysis |
| `burn` | Burn |
| `sleep` | Sleep |
| `freeze` | Freeze |

A status with a weight lower than or equal to `0` is ignored. If a Pokémon cannot receive the rolled status, the plugin tries another available status.

#### HP

`hp.lossPercentRange` defines the range of max HP percentage to remove.

```json
"hp": {
  "lossPercentRange": [5, 10]
}
```

With `[5, 10]`, the Pokémon will lose between `5%` and `10%` of its max HP. If the value reaches `100` or more, the plugin always leaves at least `1 HP`.

#### Targets

`applyTo` controls which wild battle types are affected.

```json
"applyTo": {
  "forcedBattles": false,
  "boss": false,
  "roaming": false,
  "fishing": true,
  "safari": true
}
```

| Key | Description |
| --- | --- |
| `forcedBattles` | Applies the plugin to event-forced wild battles. |
| `boss` | Applies the plugin to Pokémon marked as boss by [CC - Pokémon Boss System](https://discord.com/channels/143824995867557888/1273021231561572363). |
| `roaming` | Applies the plugin to roaming Pokémon. |
| `fishing` | Applies the plugin to fishing encounters. |
| `safari` | Applies the plugin to Safari encounters. |

#### Exclusions

`exclude` prevents the plugin from applying to specific species or maps.

```json
"exclude": {
  "species": [":mewtwo", ":pikachu"],
  "maps": [3, 12, 42]
}
```

| Key | Description |
| --- | --- |
| `species` | List of species `db_symbol` values to ignore. Values must be written as JSON strings, for example `":mewtwo"`. |
| `maps` | List of `map_id` values where the plugin should not apply. |

An excluded species is simply skipped during the battle. An excluded map disables the plugin for the whole wild encounter.

JSON does not allow unquoted Ruby symbols such as `:mewtwo`. Write them as strings instead, for example `":mewtwo"`; the plugin converts them back to `:mewtwo` internally. The `"mewtwo"` form is also accepted.
