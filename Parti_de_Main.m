%%%%%%%%%
%du code ici (pour des raisons de confidentialites je peux pas tout montrer)
%% CALCULATIONS
    %% Variables initialisation

% Call for weather data
latitude = 48.40; %Brest
longitude = -4.48;
start_date = '2023-01-01'; % Date de début de la période d'analyse
end_date   = '2023-01-02'; % Date de fin de la période d'analyse

url = sprintf(['https://archive-api.open-meteo.com/v1/archive?', ...
    'latitude=%f&longitude=%f&start_date=%s&end_date=%s&hourly=', ...
    'temperature_2m,precipitation,rain,direct_radiation,diffuse_radiation,', ...
    'dew_point_2m,wind_speed_10m,soil_temperature_100_to_255cm'], ...
    latitude, longitude, start_date, end_date); 
% Construction de l'URL de l'API Open-Meteo :
% - Domaine : archive-api.open-meteo.com
% - Coordonnées : latitude et longitude
% - Période : start_date et end_date
% - Fréquence : données horaires
% - Variables demandées : température de l'air, précipitations, pluie,
%   rayonnement direct et diffus, point de rosée, vitesse du vent à 10 m,
%   température du sol entre 100 et 255 cm

%% Lecture des données JSON
opts = weboptions('ContentType', 'json', 'Timeout', 30); 
% Définition des options pour l'appel API :
% - ContentType : les données doivent être retournées au format JSON
% - Timeout : délai d’attente de 30 secondes (utile si le serveur est lent
%   ou si la requête échoue temporairement)

weather = webread(url, opts); 
% Lecture des données météorologiques depuis l’API avec l’URL construite
% et les options définies ci-dessus. 
% Le résultat est directement stocké dans la structure "weather".


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


% Cette partie consiste l'extraction des données qu'on veut
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
    for k = 1:p_t
        A(p_t*(z-1) + k) = qr(z);
    end
end
qr = A;

n = (n-1)*p_t + 1;
s_t = s_t/p_t;
s_t_reference = s_t;
%%%%%%%%%%%%%%%%%
%du code ici
figure(100), clf, hold on
plot(Time,Tp-273.15,'k','LineWidth',1), ylabel({'Pond' 'Temperature'  '(^oC)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14; 
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure100.png')

figure(101), clf, hold on
plot(Time,pH,'k','LineWidth',1), ylabel('pH','Fontsize',18);
ax = gca; datetick('x','dd-mmm-yyyy');
ax.FontSize = 14; ylim([6.0 12])
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure101.png')

figure(102), clf, hold on
plot(Time,DO,'k','LineWidth',1), ylabel({'Dissolved Oxygen'  '(mg.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure102.png')

figure(103), clf, hold on
plot(Time,X_algae*1000,'k'), ylabel({'Algae concentration' '(g TSS.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure103.png')

figure(104), clf, hold on
plot(Time,IC,'k'), ylabel({'Inorganic Carbon' '(mg.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure104.png')

figure(105), clf, hold on
plot(Time,Sigma*50,'k'), ylabel({'Alkalinity' '(mg CaCO_3.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure105.png')

figure(106), clf, hold on
plot(Time,IP,'k'), ylabel({'PO_4^3^-' '(mg.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure106.png')

figure(107), clf, hold on
plot(Time,X_bacteria,'k'), ylabel({'Heterotrophic bacteria' '(mg.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure107.png')

figure(108), clf, hold on
plot(Time,bCOD,'k'), ylabel({'bCOD' '(mg.L^-^1)'},'Fontsize',18);
xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax = gca; ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure108.png')

figure(109), clf, hold on
plot(Time,X_nit,'k'), ylabel({'Nitrifying bacteria' '(mg.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure109.png')

figure(110), clf, hold on
plot(Time, X_algae*1000 + (X_nit + X_bacteria + X_debris_a)/0.9,'k'), ylabel({'TSS concentration' '(mg.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure110.png')

figure(111), clf, hold on
plot(Time, IN), ylabel({'Ammoniac N' '(mg N.L^-^1)'},'Fontsize',18);
ax = gca; xlim(gca,[Time(1) Time(end)]); datetick('x','dd-mmm-yyyy');
ax.FontSize = 14;
ax.XTickLabelRotation = 45;
saveas(gcf, 'figure111.png')
