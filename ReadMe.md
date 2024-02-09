# Attaque CPA sur un chiffrement AES implanté dans un FPGA

## Introduction

### Objectif du TP :

Réaliser l’attaque CPA d’un chiffrement AES implanté dans un FPGA à partir de traces fournies. L’attaque ne cible que le premier octet de la clé secrète. Le code de l’attaque sera développé avec MATLAB.
<img width="691" alt="Capture d’écran 2024-02-09 à 12 05 23" src="https://github.com/Robi04/CPA/assets/63416313/88c7e358-76b6-497b-82b4-3b6ac1e36222">

## Explication de code :

```matlab
inputs = load('inputs.mat').Inputs1;
subBytes = load('subBytes.mat').SubBytes;
traces = load('traces1000x512.mat').traces;
```

Ces lignes de code chargent des données depuis des fichiers `.mat`, qui sont des fichiers spécifiques à MATLAB contenant des données sauvegardées dans des variables. `inputs` contiendra les données d'entrée pour le chiffrement, `subBytes` est une table utilisée pour la substitution des octets pendant le chiffrement AES `S-BOX de 256 bytes` , et `traces` contient des traces de consommation de puissance mesurées lors du chiffrement.

```matlab
% On init les var
num_traces = size(traces, 1);
num_time_samples = size(traces, 2);
num_keys = 256;
P = zeros(num_traces, num_keys);
```

Ici, on initialise plusieurs variables.

- `num_traces` contient le nombre de traces de consommation de puissance.
- `num_time_samples` est le nombre de mesures de temps pour chaque trace.
- `num_keys` est fixé à 256 car c'est le nombre de valeurs possibles pour un octet (de 0 à 255).
- `P` est une matrice initialisée à zéro qui va stocker les poids de Hamming calculés.

```matlab
% On ne regarde que l'octet de poids faible de chaque bloc
for k = 0:num_keys-1
	for i = 1:num_traces
```

Ces lignes commencent deux boucles imbriquées.

1. La première boucle passe en revue toutes les clés possibles (de 0 à 255).
2. La deuxième boucle itère à travers chaque trace de consommation de puissance.

```matlab
% Ici on cast en int pour s'assurer la faisabilité de faire l'XOR
input_byte = uint8(inputs(i));
```

Avant de faire une opération XOR, nous devons nous assurer que l'entrée est de type entier. Cette ligne convertit l'entrée actuelle en un entier de 8 bits.

```matlab
% Application de l'étape AddRoundKey
roundKeyOutput = bitxor(input_byte, uint8(k));
```

Cette ligne effectue l'opération AddRoundKey, qui est une opération XOR entre l'octet d'entrée et la clé candidate.

```matlab
% Application de l'étape SubBytes
subByteOutput = subBytes(roundKeyOutput+1);
```

Ensuite, nous utilisons le résultat du XOR pour trouver la valeur correspondante dans la table de substitution `subBytes`.

```
% Ici nous allons estimer le poids de hamming de la sortie de la SBOX (étape SubBytes)
P(i, k+1) = sum(dec2bin(subByteOutput, 8) == '1');
```

Ici, nous calculons le poids de Hamming de la sortie SubBytes. Le poids de Hamming est le nombre de bits à 1 dans une valeur. On convertit l'octet en binaire, puis on compte combien de bits sont à 1.

```
% Table de coef de correlation
correlation_matrix = zeros(num_keys, num_time_samples);
```

On initialise une matrice pour stocker les coefficients de corrélation.

```
for k = 1:num_keys
	for t = 1:num_time_samples
		R = corrcoef(P(:, k), traces(:, t));
		correlation_matrix(k, t) = R(1, 2);
	end
end
```

Ces boucles calculent le coefficient de corrélation entre le poids de Hamming estimé et les traces de consommation de puissance.
Ce coefficient est un indicateur de la relation entre les deux séries de données.

```
% Trouve la clé avec la corrélation maximale
[~, max_key_index] = max(max(correlation_matrix, [], 2));
```

Cette ligne cherche l'indice de la clé avec la plus haute corrélation dans notre matrice de corrélation.
La fonction `max(correlation_matrix, [], 2)` trouve le maximum de chaque ligne (la corrélation la plus élevée pour chaque clé potentielle) dans la matrice de corrélation. Ensuite, `max(...)` est à nouveau appelé sur le résultat pour trouver la plus haute valeur parmi ces max, donnant ainsi la valeur maximale globale.
Le `~` Permet de ne pas stocker directement la valeur mais l'indice ou se trouver notre corrélation max ce qui va nous permettre d'aller la chercher pour l'afficher au lieu de juste voir notre pourcentage de correlation.

### Plotting

```
% Plotting 2d
plot(correlation_matrix(max_key_index, :));
title('2D Correlation Plot');
xlabel('Time Sample');
ylabel('Correlation');
```

<img width="672" alt="Capture d’écran 2024-02-09 à 12 05 07" src="https://github.com/Robi04/CPA/assets/63416313/8f492691-2949-4baa-9381-10ebe4babe3e">
Cette commande crée un graphique 2D montrant la corrélation de la clé la plus probable (celle avec l'indice `max_key_index`) avec toutes les autres. Les données de corrélation pour cette clé spécifique sont extraites et tracées sur le graphique.
Cela permet de visualiser comment cette clé particulière se compare aux autres en termes de corrélation à travers différentes échantillons de temps

```
% Plotting 3D
surf(correlation_matrix);
title('3D Correlation Surface');
xlabel('Time Sample');
ylabel('Key');
zlabel('Correlation');
```

<img width="672" alt="Capture d’écran 2024-02-09 à 11 54 52" src="https://github.com/Robi04/CPA/assets/63416313/a611ec39-f91d-4ceb-8c68-82b163e9fb80">

```
surf(correlation_matrix);
```

- Cette ligne crée un graphique 3D (surface) de la matrice de corrélation. La fonction `surf` est utilisée pour visualiser les données de corrélation dans un format qui montre comment la corrélation change avec différentes clés et à travers différents échantillons de temps.
- Je ne connaissais pas cette fonction mais je trouve que le résultat est difficilement interprétable
