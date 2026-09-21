# Targeted Rerolls UI-gids

Dit document beschrijft hoe de UI is opgebouwd, welke teksten gelokaliseerd moeten worden en waar oude of dubbele knoplogica kan blijven hangen.

## 1. UI-opbouw

De mod heeft drie zichtbare UI-lagen:

```text
Shop
└── Targeted Reroll-knop
    ├── opent de catalogus
    └── verandert tijdens een actieve search in Stop

Catalogus-popup
├── categorie-cyclus
├── kaartcollectie
│   └── Select / Selected / Unavailable per kaart
└── onderste bedieningsbalk
    ├── Back
    ├── Keep + numerieke invoer
    ├── Reroll (aantal geselecteerde targets)
    └── Clear
```

### Verantwoordelijkheid per bestand

| Bestand | Verantwoordelijkheid |
|---|---|
| `src/catalog.lua` | Bouwt shopknop, popup, kaartknoppen en popup-bedieningsbalk |
| `src/search.lua` | Start, stopt en beëindigt de reroll-search |
| `src/input.lua` | Numerieke invoer en muisklik op Stop tijdens een actieve search |
| `src/hooks.lua` | Voegt de knop toe aan de vanilla shop en blokkeert vanilla reroll tijdens search |
| `src/state.lua` | Bewaart UI-state en geselecteerde targets |
| `localization/default.lua` | Engelse fallbackteksten |
| `localization/nl.lua` | Nederlandse overrides wanneer taal `nl` actief is |

## 2. Verschil tussen UIBox-button en tekstnode

Dit is een belangrijke bron van visuele fouten.

### `UIBox_button.label` verwacht een tabel

```lua
UIBox_button({
    label = {localize('tagr_back')}
})
```

### `G.UIT.T.config.text` verwacht een string

```lua
{
    n = G.UIT.T,
    config = {
        text = localize('tagr_keep')
    }
}
```

Gebruik hier dus niet:

```lua
text = {localize('tagr_keep')}
```

Dat toont een Lua-table in plaats van de tekst. De nummers die dan zichtbaar worden zijn de interne inhoud/referentie van die table.

## 3. Huidige gelokaliseerde teksten

Gebruik één prefix voor alle sleutels:

```lua
misc = {
    dictionary = {
        tagr_shop_reroll = "Targeted Reroll",
        tagr_shop_stop = "Stop",
        tagr_select = "Select",
        tagr_selected = "Selected",
        tagr_unavailable = "Unavailable",
        tagr_back = "Back",
        tagr_clear = "Clear",
        tagr_keep = "Keep"
    },
    v_dictionary = {
        tagr_roll_count = "Reroll (#1#)"
    }
}
```

Voor Nederlands moeten dezelfde sleutels bestaan:

```lua
tagr_shop_reroll = "Gericht rollen"
tagr_shop_stop = "Stop"
tagr_select = "Selecteer"
tagr_selected = "Geselecteerd"
tagr_unavailable = "Niet beschikbaar"
tagr_back = "Terug"
tagr_clear = "Wissen"
tagr_keep = "Behoud"
tagr_roll_count = "Opnieuw rollen (#1#)"
```

Een vertaling wordt alleen gebruikt als de actieve taal overeenkomt met het bestand. `localization/default.lua` blijft de fallback. Alleen `nl.lua` toevoegen maakt Nederlands niet automatisch een beschikbare gametaal.

## 4. Dynamische Reroll-tekst

`Reroll (x)` is geen gewone dictionarytekst, omdat `x` dynamisch is. Gebruik een `v_dictionary`-template met `#1#`.

Conceptueel:

```lua
local template = localize('tagr_roll_count', 'v_dictionary')
local label = template:gsub('#1#', tostring(selected_count()))
```

De tekst moet opnieuw worden berekend wanneer:

- de popup wordt geopend;
- een kaart wordt geselecteerd;
- een kaart wordt gedeselecteerd;
- `Clear` wordt gebruikt.

Roep de helper aan vóór de popup wordt opgebouwd. De initiële waarde in `state.lua` mag alleen een vroege fallback zijn; de runtimewaarde moet bij het openen worden vernieuwd.

## 5. Overblijfselen en dubbele UI-logica

Deze punten zijn momenteel plekken om op te ruimen of bewust te controleren.

### 5.1 Hardcoded initiële shoplabel

`state.lua` initialiseert:

```lua
button_label = 'Targeted Reroll'
```

Dat is een fallback, maar kan de eerste zichtbare shopknop onvertaald maken. De waarde moet vóór of tijdens het bouwen van de shopknop met `localize('tagr_shop_reroll')` worden gevuld.

De `lines`-parameter van `shop_button()` is niet leidend wanneer `ref_table` en `ref_value` zijn opgegeven. In dat geval gebruikt de tekstnode de waarde uit de state-table. Daardoor kan een meegegeven vertaalde `lines`-waarde alsnog genegeerd worden.

### 5.2 Hardcoded cataloguslabels

Controleer alle waarden die rechtstreeks in state worden gezet:

```lua
'SELECT'
'SELECTED'
'UNAVAILABLE'
'REROLL (0)'
```

Deze horen dictionary- of dynamic-dictionary-sleutels te gebruiken. Anders blijven precies deze knopteksten Engels terwijl `Back`, `Keep` en `Clear` wel vertaald zijn.

### 5.3 Twee verschillende Stop-routes

De Stop-knop heeft twee mechanismen:

1. `can_open_targeted_reroll_catalog()` verandert de shopknopfunctie naar `stop_targeted_reroll`.
2. `input.lua` onderschept een linkermuisklik op `targeted_reroll_button` en roept `G.FUNCS.stop_targeted_reroll()` aan.

Dit is functioneel bedoeld voor muis/controller-locks, maar lijkt op dubbele knoplogica. Houd beide alleen als controller-input en animatie-locks daadwerkelijk verschillend gedrag vereisen.

### 5.4 Vanilla reroll-knop wordt aangepast

`add_targeted_button()` zoekt recursief naar de vanilla knop met:

```lua
button == 'reroll_shop'
```

Daarna verlaagt het de hoogte van de vanilla knop en voegt het de Targeted Reroll-knop ernaast toe. Dit is geen achtergebleven knop zolang de vanilla reroll zichtbaar moet blijven. Als er visueel een dubbele Targeted Reroll verschijnt, wordt `G.UIDEF.shop` waarschijnlijk meer dan één keer gewrapt.

## 6. Aanbevolen opschoonregels

1. Gebruik voor elke zichtbare tekst één localization key.
2. Gebruik voor vaste teksten `misc.dictionary`.
3. Gebruik voor teksten met waarden `misc.v_dictionary`.
4. Gebruik bij `UIBox_button.label` een stringtable.
5. Gebruik bij `G.UIT.T.config.text` een gewone string.
6. Laat iedere statewaarde dezelfde datatype houden: altijd string óf altijd table, niet beide.
7. Bouw de shopknop maar één keer per shop-UI-definitie.
8. Laat popup-rebuilds alleen state verversen; maak geen extra knopfuncties aan.
9. Houd de Stop-logica op één functionele route en documenteer eventuele controller-uitzonderingen.
10. Zoek na elke UI-wijziging naar resterende hardcoded labels.

## 7. Controlelijst na een UI-wijziging

- [ ] `luac -p` op alle gewijzigde Lua-bestanden.
- [ ] Balatro volledig herstart, omdat localization bij startup wordt geladen.
- [ ] Shop toont precies één Targeted Reroll-knop.
- [ ] Popup toont precies één Back-, Keep-, Reroll- en Clear-knop.
- [ ] Keep is een string en geen table.
- [ ] Reroll toont `Reroll (0)` vóór selectie.
- [ ] Reroll toont het juiste aantal na selectie/deselectie.
- [ ] Select, Selected en Unavailable zijn vertaald.
- [ ] Stop verschijnt alleen tijdens een actieve search.
- [ ] Stop stopt de search zonder een extra reroll.
- [ ] Nederlandse teksten verschijnen alleen wanneer de actieve taal `nl` is.
- [ ] Geen `ERROR`-tekst door ontbrekende localization keys.
