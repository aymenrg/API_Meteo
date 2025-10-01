%%%%%%%%%
%du code ici (pour des raisons de confidentialites je peux pas tout montrer)
%% CALCULATIONS
    %% Variables initialisation
% Définition de 30 points de latitude et de longitude
% (Plus le nombre de points est élevé, plus l'interpolation sera précise)
latitude = [
    43.61;  % Toulouse
    47.22;  % Nantes
    50.63;  % Lille
    43.30;  % Marseille
    49.44;  % Rouen
    48.58;  % Strasbourg
    45.78;  % Clermont-Ferrand
    47.32;  % Tours
    43.83;  % Montpellier
    47.75;  % Orléans
    48.11;  % Le Mans
    44.84;  % Bordeaux
    48.69;  % Metz
    49.26;  % Reims
    49.18;  % Amiens
    46.58;  % Limoges
    43.95;  % Avignon
    48.83;  % Caen
    48.37   % Saint-Malo
    43.2158
    43.30246
    42.13077
    44.7729
    47.2386
    48.1805
    49.1886
    49.6530
    47.0882
    47.2901
    45.80
];

longitude = [
    1.44;   % Toulouse
    -1.55;  % Nantes
    3.07;   % Lille
    5.38;   % Marseille
    1.10;   % Rouen
    7.75;   % Strasbourg
    3.08;   % Clermont-Ferrand
    0.70;   % Tours
    3.87;   % Montpellier
    1.91;   % Orléans
    0.20;   % Le Mans
    -0.57;  % Bordeaux
    6.17;   % Metz
    4.03;   % Reims
    2.30;   % Amiens
    1.27;   % Limoges
    4.81;   % Avignon
    -0.37;  % Caen
    -2.00   % Saint-Malo
    2.3303
    -0.3927
    9.1368
    6.3633
    6.0190
    -3.0965
    -0.3588
    4.7
    2.3883
    4.3637
    3.0237
];

start_date_str = '2023-01-01'; % A changer
end_date_str = '2023-01-01';

%% Boucle sur les sites
C_values = zeros(length(latitude), 1); % Pour stocker les temps cumulés par site


for k = 1:length(longitude) 
% Boucle sur chaque point de latitude/longitude afin de calculer
% le nombre d’heures durant lesquelles le BCOD dépasse un seuil
% (le seuil sera défini ultérieurement)

       url = sprintf(['https://archive-api.open-meteo.com/v1/archive?', ...
            'latitude=%f&longitude=%f&start_date=%s&end_date=%s&hourly=', ...
            'temperature_2m,precipitation,rain,direct_radiation,diffuse_radiation,', ...
            'dew_point_2m,wind_speed_10m,soil_temperature_100_to_255cm'], ...
            latitude(k), longitude(k), start_date_str, end_date_str);
        
        %% Lecture des données JSON
        opts = weboptions('ContentType', 'json','Timeout', 30);
        % Tentative de lecture des données météo depuis l’API
        try
            weather = webread(url, opts);
        
        % Si une erreur survient (ex. problème de connexion ou données manquantes),
        % alors un avertissement est affiché, la valeur correspondante est marquée 
        % comme manquante (NaN), et la boucle passe directement à l’itération suivante.
        catch
            warning('Erreur lors de la récupération des données pour le site %d', k);
            C_values(k) = NaN; % Marquer la valeur comme manquante
            continue;
        end

        
        start_date_num = datenum(start_date_str);
        % Calculation parameters
            % n : step of time for calculation
            % p : step of depth for soil temperature calculation
            % s_t : step of time (s)
        
        %n = length(raw_data(:,1));
        p = 100;
        
        % Conversion du temps en format exploitable
        time_vector = datetime(weather.hourly.time, 'InputFormat', 'yyyy-MM-dd''T''HH:mm'); 
        % Conversion de la variable "time" issue de l’API (chaîne de caractères)
        % en objet datetime MATLAB, lisible et manipulable.
        % Le format spécifié correspond à : année-mois-jour T heure:minute.
        
        time_vector0 = datenum(time_vector); 
        % Conversion du vecteur datetime en format numérique (nombre de jours
        % écoulés depuis le 1er janvier 0000).
        % Utile pour effectuer directement des calculs sur le temps.
        
        s_t = (time_vector0(2) - time_vector0(1)) * 24 * 3600; 
        % Calcul du pas de temps entre deux mesures successives.
        % - Différence entre deux valeurs du vecteur temporel (en jours)
        % - Conversion en secondes : *24 (heures) *3600 (secondes)
        
        % Weather data are first read and stored as individual vectors
        Hs_dir = weather.hourly.direct_radiation;                         % Rayonnement direct (W/m²)
        Hs_dif = weather.hourly.diffuse_radiation;                        % Rayonnement diffus (W/m²)
        Ta = weather.hourly.temperature_2m + 273.15;
        n = length(Ta);
        
        Tdp = weather.hourly.dew_point_2m + 273.15;                        % Température du point de rosée (K)
        
        RH = zeros(n,1);
        for z =1:n
            RH(z) = Pvap(Tdp(z))/Pvap(Ta(z)) ;
        end
        
        Nu = weather.hourly.wind_speed_10m;                               % Vitesse du vent (m/s)
        
        
        qr = (weather.hourly.precipitation + weather.hourly.rain); % Mm
        qr = qr /1000/ s_t;
        
        % Weather data are then linearly interpolated to obtain data on the initial
        % time step divided by the factor p_t
        
        Hs_dir = linear_interpolation_vector(Hs_dir,p_t);
        Hs_dif = linear_interpolation_vector(Hs_dif,p_t);
        Ta = linear_interpolation_vector(Ta,p_t);
        RH = linear_interpolation_vector(RH,p_t);
        Nu = linear_interpolation_vector(Nu,p_t);
        Dw_a = -2.775*10^(-6)+4.479*10^(-8)*Ta + 1.656*10^(-10)*Ta.^2;
        
        A = zeros(p_t*(n-1) +1,1);
        for z = 1:n-1
            for h = 1:p_t
                A(p_t*(z-1) + h) = qr(z);
            end
        end
        qr = A;
        
        n = (n-1)*p_t + 1;
        s_t = s_t/p_t;
        s_t_reference = s_t;
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Time = Time(1:n);  
    % Le vecteur Time contient une entrée supplémentaire à cause du calcul à l’indice i+2.
    % On tronque donc le vecteur pour garder seulement les n premières valeurs.
    
    % Détection des intervalles où bCOD dépasse un seuil
    Time_hours = (Time - Time(1)) * 24;  
    % Conversion du vecteur temporel en heures à partir du temps initial (Time(1)).
    
    L = [];  
    % Initialisation d’une matrice vide pour stocker les intervalles détectés.
    % Chaque ligne contiendra : [début, fin, durée].
    
    seuil = 1.25;  
    % Valeur seuil de bCOD au-dessus de laquelle un intervalle est considéré.
    
    u = 1;  
    % Initialisation de l’indice de parcours du vecteur bCOD.
    
    while u < length(bCOD)  
        % Boucle principale parcourant tous les échantillons de bCOD.
        
        if bCOD(u) > seuil  
            % Si la valeur bCOD à l’instant u dépasse le seuil,
            % alors un nouvel intervalle commence.
            
            debut = Time_hours(u);  
            % Stockage du temps de début de l’intervalle.
            
            j = u;  
            % Initialisation d’un second indice pour trouver la fin de l’intervalle.
            
            while j < length(bCOD) && bCOD(j) > seuil  
                j = j + 1;  
            end
            % Cette boucle interne fait avancer j tant que bCOD reste au-dessus du seuil.
            % À la sortie, j correspond à l’instant où bCOD repasse en dessous du seuil.
            
            fin = Time_hours(j);  
            % Stockage du temps de fin de l’intervalle.
            
            duree = fin - debut;  
            % Calcul de la durée de l’intervalle (en heures).
            
            L = [L; debut, fin, duree];  
            % Ajout de la ligne [début, fin, durée] dans la matrice L.
            
            u = j;  
            % On saute directement à la fin de l’intervalle trouvé
            % pour continuer la détection plus efficacement.
            
        else
            u = u + 1;  
            % Si bCOD ne dépasse pas le seuil, on passe simplement à l’échantillon suivant.
        end
    end
end

temps_cumule = sum(L(:,3));  
% Somme de toutes les durées des intervalles trouvés (en heures).

C_values(k) = temps_cumule;  
% Stockage du temps cumulé (pour le site/point k) dans le vecteur de résultats.


K = C_values;
% commenataires
S = shaperead('gadm41_FRA_0.shp', 'UseGeoCoords', true);  
% Lecture du fichier shapefile contenant les frontières de la France. 
% 'UseGeoCoords' = true indique que les coordonnées sont en latitude/longitude.

% Extraire les coordonnées des frontières
lat_border = S.Lat;  
lon_border = S.Lon;  
% Récupération des vecteurs de latitude et longitude des contours du pays.

lat_vec = linspace(min(lat_border), max(lat_border), 300);  
lon_vec = linspace(min(lon_border), max(lon_border), 300);  
% Création de vecteurs réguliers de points en latitude et longitude 
% pour générer une grille couvrant toute la zone des frontières.
% Ici, 300 points sont utilisés dans chaque direction pour une bonne résolution.

[LonGrid, LatGrid] = meshgrid(lon_vec, lat_vec);  
% Génération d’une grille 2D à partir des vecteurs latitude/longitude. 
% Chaque point de la grille correspond à une coordonnée (LatGrid, LonGrid).

F = scatteredInterpolant(longitude, latitude, K, 'nearest', 'nearest');  
% Création d’une fonction d’interpolation à partir de données irrégulières (longitude, latitude, K).
% Méthode 'nearest' pour l’interpolation et l’extrapolation : chaque point de la grille prendra la valeur K du point le plus proche.

K_grid = F(LonGrid, LatGrid);  
% Application de l’interpolant sur la grille 2D. 
% Résultat : une matrice K_grid correspondant aux valeurs interpolées de K sur chaque point de la grille.

data_matrix_K = K_grid;  
% Stockage final des valeurs interpolées dans une matrice utilisable pour visualisation ou calculs ultérieurs.

% Appliquer le masque géographique
mask = inpolygon(LonGrid, LatGrid, lon_border, lat_border);
data_matrix_K(~mask) = NaN;  % Supprime tout ce qui sort du territoire

% Affichage
figure;

% Heatmap lisse
contourf(LonGrid, LatGrid, data_matrix_K, 1000, 'LineColor', 'none');  
% Crée un graphique en contours remplis (contourf) pour visualiser la matrice K.  
% LonGrid et LatGrid définissent la grille de coordonnées.  
% data_matrix_K contient les valeurs à représenter.  
% '1000' indique que 1000 niveaux de contours sont utilisés pour un rendu très lisse.  
% 'LineColor','none' supprime les lignes de contour pour obtenir un dégradé continu.

cmap = hot;  
% Sélection de la colormap "hot", qui va du noir/rouge au jaune/blanc.

cmap = flipud(cmap);  
% Inverse la colormap verticalement (flip up-down) pour que les valeurs élevées apparaissent en couleurs sombres et les basses en clair.

colormap(cmap);  
% Applique la colormap modifiée au graphique en cours.

% Add the colorbar
colorbar;
title('Durée cumulée bCOD > seuil sur la France (interpolée)')
xlabel('Longitude');
ylabel('Latitude');

% Superposer les frontières
hold on
plot(lon_border, lat_border, 'k', 'LineWidth', 1.2);

axis equal tight;
toc;