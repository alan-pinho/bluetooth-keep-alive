# Próxima sessão — ponto de retomada

Última sessão: 2026-05-11. Keep-alive por blip de áudio implementado (Opção C — auto-detect + override manual). Builds Debug+Release limpos. **Falta: exercitar smoke tests em hardware real (ver seção abaixo).**

## ✅ Keep-alive de áudio — entregue

- `Souces/Core/Services/KeepAlive/KeepAliveStrategy.swift` + `SDPQueryStrategy.swift` + `AudioBlipStrategy.swift` + `KeepAliveStrategyKind.swift` (enum String-raw `sdp`/`audio` Codable+CaseIterable).
- Migration v3 `v3_routine_keep_alive_strategy` adiciona coluna `keepAliveStrategy TEXT NULL` em `routines`.
- `Routines.keepAliveStrategy: KeepAliveStrategyKind?` (`nil` = auto).
- `BluetoothDevicePinger.ping/keepAliveMethodLabel` agora aceitam `strategyOverride: KeepAliveStrategyKind?`.
- `ClassicBluetoothPinger.strategy(for:override:)` honra override; sem override cai em `deviceClassMajor == kBluetoothDeviceClassMajorAudio`.
- `TimerRoutineService` mantém cache `strategyOverrides[id]` populado por `timerSink` (a partir de `repositoryUpdated`). `fireTick` passa o override para o pinger e loga o label usado em `routine_events.message` (`pingOk`).
- `DeviceView` ganhou picker (radioGroup): "Auto (detected: X) / SDP query / Audio blip". `DeviceViewModel.strategyOverride` é persistido em `saveRoutine` (create + update). `keepAliveMethod` é recomputado em tempo real via sink em `$strategyOverride` (não espera o save).

## ⏳ Outras pendências menores

- **Stepper interval=0**: `DeviceView` permite 0; só falha no save. Mudar `Stepper(in: 1...3600)` ou desabilitar Save quando `timeInterval == 0`.
- **BLE em rotinas**: `Routines.toRoutineModel` aceita BLE mas `PingerRegistry` só tem classic. Adicionar guard em `DeviceViewModel.saveRoutine` para `.ble(_)` OU implementar `BLEBluetoothPinger`.
- **Histórico de eventos no DeviceView**: `RoutineEventRepository.recent(routineId:limit:)` já existe; falta lista/disclosure mostrando últimas N ocorrências.
- **Ícone reativo no menu bar** (~30min): mudar o ícone quando algum routine estiver dormente ou em snooze.

## 🧪 Validação manual ainda não exercitada

Smoke tests do plano (em hardware real):
- Boot headless via SMAppService: `log stream --predicate 'process == "BluetoothKeepAlive"'` deve mostrar pings sem janela aberta.
- Dormant flow: desligar/religar fone → badge cinza→verde + eventos `disconnected`/`connected` no DB.
- Snooze: pausa 1min via menu → `snoozeSkip` no DB → resume automático.
- Migration em DB existente: rotinas antigas preservadas + tabela `routine_events` criada + `grdb_migrations` populado.
- **Em release assinado**: confirmar que `IOBluetoothDevice.register(forConnectNotifications:)` retorna callbacks com sandbox + `com.apple.security.device.bluetooth=true`.

## 📍 Como retomar

1. Ler `CLAUDE.md` para reentrar na arquitetura.
2. Exercitar smoke tests em hardware real (esp. devices de áudio: verificar que o auto-detect cai em `Audio blip` e que o override manual sobrescreve corretamente).
3. Decidir se vale escrever migration de teste para o caso "DB v2 → v3" preservando rotinas existentes (a migration v3 já é additive, mas confirmar em DB real).
