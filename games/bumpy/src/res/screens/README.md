# Screens

`loading.png`: LoadingScreen `$4000`, 6912 bytes (tape block 4, "BUMPY.SCR"), the loading screen as colour cells (64
Spectrum palette entries, index = flash x 32 + ink x 16 + bright x 8 + colour; `tx-cells` keeps the attributes of
cells that are all ink or all paper). Loaded by the BASIC's LOAD "" SCREEN$; no routine of the game reads it.
