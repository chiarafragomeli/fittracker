# My Gym Bro 🏋️‍♂️

**My Gym Bro** è un'applicazione moderna per il monitoraggio degli allenamenti in palestra, sviluppata con **Flutter** per iOS e dotata di un'app companion nativa per **Apple Watch (watchOS)** con supporto completo a **Live Activity**, **Dynamic Island** e **sincronizzazione bidirezionale in tempo reale**.

---

## ✨ Funzionalità Principali

### 📱 App iPhone (Flutter & Swift)
- **Gestione Schede e Routine**: Creazione, modifica e personalizzazione avanzata di schede di allenamento (esercizi, serie di default, ripetizioni, durate e tempi di recupero).
- **Tracciamento Allenamento Attivo**:
  - Timer sessione e timer di riposo automatico con segnali audio al termine del recupero.
  - Incremento e decremento pesi rigoroso con step di **0,25 kg**.
  - Checklist interattiva per completamento serie.
  - Minimizzazione della scheda durante l'allenamento per consultare lo storico o le altre sezioni.
- **Storico e Statistiche**:
  - Riepilogo dettagliato degli allenamenti passati con carichi massimi, ripetizioni e volume totale.
  - Import ed Export dei dati in formato **CSV** (compatibile con i formati standard delle principali app fitness).
- **Integrazione Apple Health**: Sincronizzazione calorie attive, frequenza cardiaca e sessioni di allenamento con Apple Salute.

---

### 🏝️ Dynamic Island & Live Activity (ActivityKit)
- **Timer in Tempo Reale stile Hevy**: Durante l'allenamento, il cronometro avanza in diretta nella **Dynamic Island** (forme compatta, minima ed espansa) e nella **Schermata di Blocco**.
- **Avanzamento Serie & Esercizi**: Visualizzazione dinamica del nome dell'esercizio corrente e del numero di serie (es. *Serie 2/3*).
- **Consumo Batteria Zero**: Sfrutta le API native di iOS `Text(timerInterval: ..., countsDown: false)`, gestite direttamente dal compositor del sistema operativo senza polling continuo o processi pesanti in background.

---

### ⌚ Apple Watch Companion App (watchOS Nativo - SwiftUI & HealthKit)
- **Sessioni Native HealthKit**: Tracciamento in tempo reale di battito cardiaco, battito medio, calorie bruciate e durata sessione.
- **Persistenza e Resilienza**:
  - Banner persistente in cima alla lista delle schede (*"In corso: [Nome] — Tocca per riprendere"*).
  - Ripristino automatico dell'allenamento attivo alla riapertura dell'app da qualsiasi schermata.
- **Incrementi Pesi a 0,25 kg**: Regolazione di precisione dei carichi senza salti anomali.
- **Autonomia Standalone**: Possibilità di avviare, gestire e concludere gli allenamenti direttamente dal polso anche a telefono bloccato.

---

### 🔄 Sincronizzazione Bidirezionale (WatchConnectivity)
- **Avvio e Conclusione Sincronizzati**:
  - Avviando l'allenamento dall'Apple Watch, l'iPhone si risveglia in background, attiva la Live Activity sulla Dynamic Island e mostra una notifica di sincronizzazione anche con schermo bloccato o app chiusa.
  - Scartando o completando la sessione su uno qualsiasi dei due dispositivi, lo stato si allinea istantaneamente su entrambi.
- **Sincronizzazione Serie per Serie in Tempo Reale**:
  - Spuntando una serie sull'orologio, l'iPhone riceve immediatamente il completamento, accende la spunta verde, aggiorna peso e ripetizioni e fa partire il timer di riposo sincronizzato.
  - Spuntando una serie su iPhone, l'orologio avanza automaticamente alla serie/esercizio successivo e fa partire il recupero.
- **Deduplicazione Intelligente**: Ogni allenamento condivide un identificativo univoco (`workoutId`) che previene duplicazioni accidentali nei log dello storico.

---

## 🛠️ Architettura Tecnica

```
gym_tracker/
├── lib/                                    # Codice Applicazione Flutter
│   ├── core/
│   │   ├── database/                       # Modelli Hive, Repository e Adapter
│   │   ├── services/                       # Servizio esportazione CSV e audio
│   │   ├── theme/                          # Tema dark e stili grafici
│   │   └── watch_connector.dart            # Bridge MethodChannel verso iOS & watchOS
│   ├── features/
│   │   ├── exercises/                      # Schermate e logica catalogo esercizi
│   │   ├── profile/                        # Profilo utente, storico allenamenti ed export
│   │   ├── routines/                       # Creazione e dettaglio schede
│   │   └── workout/                        # Allenamento attivo, timer e state provider
│   └── main.dart                           # Entry point applicazione
│
└── ios/                                    # Codice Nativo Apple
    ├── Runner/
    │   ├── AppDelegate.swift               # Gestione WatchConnectivity, canali e Live Activity
    │   └── Info.plist                      # Configurazione permessi e NSSupportsLiveActivities
    ├── MyGymBroWidgets/                    # Widget Extension (ActivityKit)
    │   ├── WorkoutLiveActivity.swift       # Widget Dynamic Island e Lock Screen
    │   └── WorkoutActivityAttributes.swift # Modello attributi Live Activity
    └── GymTrackerWatch Watch App/          # App Companion Apple Watch (watchOS)
        ├── GymTrackerWatchApp.swift        # Entry point SwiftUI Watch
        ├── Services/
        │   ├── WorkoutManager.swift        # Gestione HKWorkoutSession e timer recupero
        │   └── ConnectivityManager.swift   # Canale WCSession bidirezionale
        └── Views/                          # Interfacce SwiftUI per Apple Watch
```

---

## 🚀 Requisiti e Installazione

### Prerequisiti
- **Flutter SDK**: `>= 3.24.0`
- **Xcode**: `>= 16.0`
- **Dispositivi Target**:
  - **iPhone**: iOS 16.1 o superiore (per Live Activities e Dynamic Island).
  - **Apple Watch**: watchOS 9.0 o superiore.
- **Apple Developer Account**: Per il code-signing e il deployment su dispositivi fisici.

### Setup Locale

1. **Clona il repository**:
   ```bash
   git clone https://github.com/chiarafragomeli/fittracker.git
   cd fittracker
   ```

2. **Installa le dipendenze Flutter**:
   ```bash
   flutter pub get
   ```

3. **Compilazione ed Esecuzione**:
   - Per testare su iPhone:
     ```bash
     flutter run -d <DEVICE_ID_IPHONE>
     ```
   - Per compilare la build di produzione iOS (incluso Watch e Widget Extension):
     ```bash
     flutter build ios --release
     ```

---

## 📄 Licenza
Questo progetto è sviluppato per uso personale e distribuito secondo i termini della licenza specificata nel repository.
